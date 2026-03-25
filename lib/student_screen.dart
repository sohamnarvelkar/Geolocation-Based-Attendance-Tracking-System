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

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'my_attendance_screen.dart';
import 'attendance_percentage_screen.dart';
import 'login_screen.dart';

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

  // 📍 Attendance Logic (FIXED GPS ISSUE)
  Future<void> markAttendance(String qrData) async {
    try {
      var data = jsonDecode(qrData);

      double teacherLat = data['latitude'];
      double teacherLng = data['longitude'];
      String classId = data['classId'];

      final user = FirebaseAuth.instance.currentUser;

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

      // 🔥 FIRST LOCATION
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // 🔥 WAIT FOR BETTER GPS FIX
      await Future.delayed(const Duration(seconds: 2));

      // 🔥 SECOND LOCATION (MORE ACCURATE)
      Position updatedPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      double distance = Geolocator.distanceBetween(
        teacherLat,
        teacherLng,
        updatedPosition.latitude,
        updatedPosition.longitude,
      );

      print("Teacher: $teacherLat, $teacherLng");
      print(
        "Student: ${updatedPosition.latitude}, ${updatedPosition.longitude}",
      );
      print("Distance: $distance");

      // 🔥 KEEP DISTANCE = 12 (AS YOU SAID)
      if (distance <= 12) {
        String studentId = user!.uid;

        String deviceId = await getDeviceId();

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

        await FirebaseFirestore.instance.collection("attendance").add({
          "studentId": studentId,
          "studentEmail": user.email ?? "N/A",
          "studentName": user.email ?? "Student",
          "classId": classId,
          "deviceId": deviceId,
          "latitude": updatedPosition.latitude,
          "longitude": updatedPosition.longitude,
          "time": DateTime.now(),
        });

        // Custom styled prominent SnackBar for success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Attendance Marked ✅",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            backgroundColor: const Color(0xFF3E6B4A), // primaryGreen
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          )
        );
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

  // 📷 Gallery QR Scan (UNCHANGED)
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

  // Helper widget to create uniform, styled buttons
  Widget _buildDashboardMenuButton({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
    required Color bgColor,
    required Color fgColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 65,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 28),
          label: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Local color variables for the theme
    const Color primaryGreen = Color(0xFF3E6B4A);
    const Color lightGreen = Color(0xFF6F9A73);
    const Color offWhiteBackground = Color(0xFFF9F1DF);
    const Color darkText = Color(0xFF2A3B2F);

    return Scaffold(
      backgroundColor: offWhiteBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Student Dashboard",
          style: TextStyle(color: darkText, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: darkText),
      ),
      body: scanning
          ? Stack(
              children: [
                MobileScanner(
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
                ),
                // Add a back button overlay when scanning
                Positioned(
                  top: 40,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
                    onPressed: () {
                      setState(() {
                        scanning = false;
                      });
                    },
                  ),
                ),
                const Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      "Scanning QR Code...",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              ],
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      size: 80,
                      color: primaryGreen,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Ready for Class?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Select an option below to manage your attendance.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: lightGreen,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Main Action Buttons
                    _buildDashboardMenuButton(
                      title: "Scan QR",
                      icon: Icons.qr_code_scanner_rounded,
                      bgColor: primaryGreen,
                      fgColor: offWhiteBackground,
                      onPressed: () {
                        setState(() {
                          scanning = true;
                        });
                      },
                    ),

                    _buildDashboardMenuButton(
                      title: "Upload from Gallery",
                      icon: Icons.image_rounded,
                      bgColor: Colors.white,
                      fgColor: darkText,
                      onPressed: pickFromGallery,
                    ),

                    _buildDashboardMenuButton(
                      title: "My Attendance",
                      icon: Icons.history_rounded,
                      bgColor: Colors.white,
                      fgColor: darkText,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyAttendanceScreen(),
                          ),
                        );
                      },
                    ),

                    _buildDashboardMenuButton(
                      title: "Attendance Percentage",
                      icon: Icons.pie_chart_rounded,
                      bgColor: Colors.white,
                      fgColor: darkText,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AttendancePercentageScreen(),
                          ),
                        );
                      },
                    ),

                    const Spacer(),

                    // Logout Button (Styled slightly differently to stand out)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: TextButton.icon(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                        label: const Text(
                          "Logout",
                          style: TextStyle(fontSize: 16, color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}