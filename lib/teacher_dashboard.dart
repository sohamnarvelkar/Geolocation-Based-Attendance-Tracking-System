import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'attendance_list_screen.dart';
import 'past_classes_screen.dart';
import 'teacher_students_screen.dart';

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

  // 🔥 CREATE CLASS
  Future<void> createClass() async {
    setState(() => loading = true);

    try {
      await Geolocator.requestPermission();
      Position position = await Geolocator.getCurrentPosition();

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

      // 🔥 QR SAFE DATA
      qrData = jsonEncode({
        "classId": id,
        "latitude": position.latitude,
        "longitude": position.longitude,
      });

      setState(() {
        classId = id;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Class Started ✅")));
    } catch (e) {
      print(e);
    }

    setState(() => loading = false);
  }

  // 🔥 CLOSE QR (UPDATED)
  Future<void> closeQr() async {
    endTime = DateTime.now();

    await FirebaseFirestore.instance.collection("classes").doc(classId).update({
      "endTime": endTime,
    });

    // 🔥 HIDE QR AFTER CLOSING
    setState(() {
      qrData = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("QR Closed ⛔")));
  }

  // 🔥 PERFECT QR SHARE (NO CUTTING)
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

      // 🔥 WHITE BACKGROUND
      final paint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, totalSize, totalSize), paint);

      // 🔥 CENTER QR
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Teacher ${widget.name}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📚 SUBJECT
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: "Subject",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // 🔘 START CLASS
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: createClass,
                    child: const Text("Start Class"),
                  ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TeacherStudentsScreen(teacherName: widget.name),
                  ),
                );
              },
              child: const Text("My Students"),
            ),

            const SizedBox(height: 10),

            // 📊 PAST ATTENDANCE
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PastClassesScreen()),
                );
              },
              child: const Text("Past Attendance"),
            ),

            const SizedBox(height: 20),

            // 🔥 QR SECTION
            if (qrData != null)
              Column(
                children: [
                  // ✅ PERFECT QR
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(30),
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(10),
                      child: QrImageView(
                        data: qrData!,
                        size: 220,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: shareQrImage,
                    child: const Text("Share QR"),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: closeQr,
                    child: const Text("Close QR"),
                  ),

                  const SizedBox(height: 10),

                  if (endTime != null)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttendanceListScreen(
                              classId: classId!,
                              subject: subjectController.text,
                              startTime: startTime!,
                              endTime: endTime!,
                            ),
                          ),
                        );
                      },
                      child: const Text("View Attendance"),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
