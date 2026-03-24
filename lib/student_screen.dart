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

      await Geolocator.requestPermission();
      Position position = await Geolocator.getCurrentPosition();

      double distance = Geolocator.distanceBetween(
        teacherLat,
        teacherLng,
        position.latitude,
        position.longitude,
      );

      if (distance <= 11) {
        String studentId = user!.uid;

        // 🔒 Prevent duplicate
        var existing = await FirebaseFirestore.instance
            .collection("attendance")
            .where("studentId", isEqualTo: studentId)
            .where("classId", isEqualTo: classId)
            .get();

        if (existing.docs.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Already Marked ❗")));
        } else {
          await FirebaseFirestore.instance.collection("attendance").add({
            "studentId": studentId,
            "studentEmail": user.email ?? "N/A", // ✅ FIX
            "studentName":
                user.email ?? "Student", // ✅ FIX (use real name later)
            "classId": classId,
            "latitude": position.latitude,
            "longitude": position.longitude,
            "time": DateTime.now(), // ✅ FIX
          });

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Attendance Marked ✅")));
        }
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
