import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    as mlkit;

// 🔥 NEW IMPORTS
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// 🔥 DEVICE ID FUNCTION
Future<String> getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();

  String? deviceId = prefs.getString('device_id');

  if (deviceId == null) {
    deviceId = const Uuid().v4();
    await prefs.setString('device_id', deviceId);
  }

  return deviceId;
}

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  bool scanning = false;
  bool scannedOnce = false;

  // 📍 Attendance Logic
  Future<void> markAttendance(String qrData) async {
    try {
      var data = jsonDecode(qrData);

      double teacherLat = data['latitude'];
      double teacherLng = data['longitude'];
      String classId = data['classId'];

      final user = FirebaseAuth.instance.currentUser;

      // 🔥 CHECK IF CLASS IS CLOSED
      var classDoc = await FirebaseFirestore.instance
          .collection("classes")
          .doc(classId)
          .get();

      if (!classDoc.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Invalid Class ❌")));
        return;
      }

      var classData = classDoc.data()!;

      if (classData["endTime"] != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("QR Expired or Closed ❌")));
        return;
      }

      await Geolocator.requestPermission();

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double distance = Geolocator.distanceBetween(
        teacherLat,
        teacherLng,
        position.latitude,
        position.longitude,
      );

      print("Distance: $distance");

      if (distance <= 11) {
        String studentId = user!.uid;

        // 🔥 GET DEVICE ID
        String deviceId = await getDeviceId();

        // 🔒 CHECK 1: STUDENT ALREADY MARKED
        var existingStudent = await FirebaseFirestore.instance
            .collection("attendance")
            .where("studentId", isEqualTo: studentId)
            .where("classId", isEqualTo: classId)
            .get();

        if (existingStudent.docs.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Already Marked ❗")));
          return;
        }

        // 🔒 CHECK 2: DEVICE ALREADY USED
        var existingDevice = await FirebaseFirestore.instance
            .collection("attendance")
            .where("deviceId", isEqualTo: deviceId)
            .where("classId", isEqualTo: classId)
            .get();

        if (existingDevice.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("This device already used ❌")),
          );
          return;
        }

        // ✅ SAVE ATTENDANCE
        await FirebaseFirestore.instance.collection("attendance").add({
          "studentId": studentId,
          "studentEmail": user.email ?? "N/A",
          "studentName": user.email ?? "Student",
          "classId": classId,
          "deviceId": deviceId, // 🔥 IMPORTANT
          "latitude": position.latitude,
          "longitude": position.longitude,
          "time": DateTime.now(),
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Attendance Marked ✅")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("You are too far ❌")));
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid QR ❌")));
    }

    setState(() {
      scanning = false;
      scannedOnce = false;
    });
  }

  // 📷 Gallery QR Scan
  Future<void> pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final inputImage = mlkit.InputImage.fromFile(File(image.path));
      final barcodeScanner = mlkit.BarcodeScanner();

      final List<mlkit.Barcode> barcodes = await barcodeScanner.processImage(
        inputImage,
      );

      if (barcodes.isNotEmpty) {
        final String? qrData = barcodes.first.rawValue;

        if (qrData != null) {
          markAttendance(qrData);
        }
      }

      barcodeScanner.close();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Dashboard")),
      body: Center(
        child: scanning
            ? MobileScanner(
                onDetect: (barcodeCapture) {
                  if (scannedOnce) return;

                  final barcodes = barcodeCapture.barcodes;

                  for (final barcode in barcodes) {
                    final String? code = barcode.rawValue;

                    if (code != null) {
                      scannedOnce = true;
                      markAttendance(code);
                      break;
                    }
                  }
                },
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        scanning = true;
                      });
                    },
                    child: const Text("Scan QR"),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: pickFromGallery,
                    child: const Text("Upload from Gallery"),
                  ),
                ],
              ),
      ),
    );
  }
}
