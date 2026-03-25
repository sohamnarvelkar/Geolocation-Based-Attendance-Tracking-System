import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendancePercentageScreen extends StatefulWidget {
  const AttendancePercentageScreen({super.key});

  @override
  State<AttendancePercentageScreen> createState() =>
      _AttendancePercentageScreenState();
}

class _AttendancePercentageScreenState
    extends State<AttendancePercentageScreen> {
  int totalClasses = 0;
  int attendedClasses = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    String studentId = FirebaseAuth.instance.currentUser!.uid;

    // 🔥 TOTAL CLASSES CREATED
    var classesSnapshot =
        await FirebaseFirestore.instance.collection("classes").get();

    // 🔥 ATTENDED CLASSES
    var attendanceSnapshot = await FirebaseFirestore.instance
        .collection("attendance")
        .where("studentId", isEqualTo: studentId)
        .get();

    setState(() {
      totalClasses = classesSnapshot.docs.length;
      attendedClasses = attendanceSnapshot.docs.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    int notAttended = totalClasses - attendedClasses;
    double percentage = totalClasses == 0
        ? 0
        : (attendedClasses / totalClasses) * 100;

    return Scaffold(
      appBar: AppBar(title: const Text("Attendance Percentage")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Total Classes: $totalClasses",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),

            Text(
              "Attended: $attendedClasses",
              style: const TextStyle(fontSize: 20, color: Colors.green),
            ),
            const SizedBox(height: 10),

            Text(
              "Not Attended: $notAttended",
              style: const TextStyle(fontSize: 20, color: Colors.red),
            ),
            const SizedBox(height: 20),

            Text(
              "Percentage: ${percentage.toStringAsFixed(2)}%",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}