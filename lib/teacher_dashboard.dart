import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'past_classes_screen.dart';
import 'teacher_students_screen.dart';
import 'map_screen.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherDashboard extends StatefulWidget {
  final String name;

  const TeacherDashboard({super.key, required this.name});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final subjectController = TextEditingController();

  bool loading = false;
  String? classId;
  String? qrData;

  DateTime? startTime;
  DateTime? endTime;

  double? teacherLat;
  double? teacherLng;

  // 🔥 CREATE CLASS
  Future<void> createClass() async {
    if (subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a subject name first.")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await Geolocator.requestPermission();
      Position position = await Geolocator.getCurrentPosition();

      teacherLat = position.latitude;
      teacherLng = position.longitude;

      String id = DateTime.now().millisecondsSinceEpoch.toString();
      startTime = DateTime.now();

      await FirebaseFirestore.instance.collection("classes").doc(id).set({
        "classId": id,
        "subject": subjectController.text.trim(),
        "teacherName": widget.name,
        "latitude": position.latitude,
        "longitude": position.longitude,
        "radius": 50,
        "startTime": startTime,
        "endTime": null,
      });

      qrData = jsonEncode({
        "classId": id,
        "latitude": position.latitude,
        "longitude": position.longitude,
      });

      setState(() {
        classId = id;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Class Started ✅", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF3E6B4A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        )
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }

    setState(() => loading = false);
  }

  // 🔥 CLOSE QR
  Future<void> closeQr() async {
    endTime = DateTime.now();

    await FirebaseFirestore.instance.collection("classes").doc(classId).update({
      "endTime": endTime,
    });

    setState(() {
      qrData = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("QR Closed ⛔", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFD9534F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      )
    );
  }

  // 🔥 SHARE QR
  Future<void> shareQrImage() async {
    try {
      const int qrSize = 500;
      const double margin = 100;

      final painter = QrPainter(
        data: qrData!,
        version: QrVersions.auto,
        gapless: true,
        color: Colors.black,
        emptyColor: Colors.white,
      );

      final qrImage = await painter.toImage(qrSize.toDouble());

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final totalSize = qrSize + (margin * 2);

      final paint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, totalSize, totalSize), paint);

      canvas.drawImage(qrImage, Offset(margin, margin), Paint());

      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(
        totalSize.toInt(),
        totalSize.toInt(),
      );

      final byteData = await finalImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/qr.png');

      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      print("QR Share Error: $e");
    }
  }

  void openMap() async {
    if (teacherLat == null || teacherLng == null) return;

    List<Map<String, double>> students = [];

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection("attendance")
          .where("classId", isEqualTo: classId)
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data();
        students.add({"lat": data["latitude"], "lng": data["longitude"]});
      }
    } catch (e) {
      print(e);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapScreen(
          teacherLat: teacherLat!,
          teacherLng: teacherLng!,
          students: students,
        ),
      ),
    );
  }

  // Helper for grid action buttons
  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap, Color iconColor) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A3B2F), // darkText
              ),
            ),
          ],
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
    const Color dangerRed = Color(0xFFD9534F);

    return Scaffold(
      backgroundColor: offWhiteBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Teacher Dashboard",
              style: TextStyle(color: lightGreen, fontSize: 14),
            ),
            Text(
              widget.name,
              style: const TextStyle(color: darkText, fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: dangerRed),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subject Input Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Create a New Session",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: subjectController,
                    style: const TextStyle(color: darkText, fontSize: 16),
                    enabled: qrData == null, // Disable editing if class is active
                    decoration: InputDecoration(
                      labelText: "Enter Subject Name",
                      labelStyle: const TextStyle(color: lightGreen),
                      prefixIcon: const Icon(Icons.book_outlined, color: primaryGreen),
                      filled: true,
                      fillColor: offWhiteBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Start Class Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: loading
                        ? const Center(child: CircularProgressIndicator(color: primaryGreen))
                        : ElevatedButton(
                            onPressed: qrData == null ? createClass : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: lightGreen.withOpacity(0.3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: qrData == null ? 4 : 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.play_arrow_rounded),
                                const SizedBox(width: 8),
                                Text(
                                  qrData == null ? "Start Class & Generate QR" : "Class is Active",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Dashboard Grid Options
            const Text(
              "Tools",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildActionCard(
                  "Map View", 
                  Icons.map_rounded, 
                  openMap, 
                  primaryGreen
                ),
                _buildActionCard(
                  "My Students", 
                  Icons.people_alt_rounded, 
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherStudentsScreen(teacherName: widget.name),
                      ),
                    );
                  }, 
                  Colors.blueAccent
                ),
                _buildActionCard(
                  "Past Classes", 
                  Icons.history_rounded, 
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PastClassesScreen()),
                    );
                  }, 
                  Colors.orangeAccent
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Active QR Code Section
            if (qrData != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "Active Class QR",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Ask students to scan this to mark attendance.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    
                    // The QR Code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: qrData!,
                        size: 220,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // QR Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: shareQrImage,
                          icon: const Icon(Icons.share_rounded, color: primaryGreen),
                          label: const Text("Share", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: closeQr,
                          icon: const Icon(Icons.stop_circle_rounded, color: Colors.white),
                          label: const Text("Close Class", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dangerRed,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}