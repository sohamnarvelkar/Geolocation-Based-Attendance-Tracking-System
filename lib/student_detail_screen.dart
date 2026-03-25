import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String teacherName;

  const StudentDetailScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.teacherName,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  int totalClasses = 0;
  int attended = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    // 🔥 GET CLASSES OF THIS TEACHER
    var classSnapshot = await FirebaseFirestore.instance
        .collection("classes")
        .where("teacherName", isEqualTo: widget.teacherName)
        .get();

    var classIds = classSnapshot.docs.map((e) => e.id).toList();

    totalClasses = classIds.length;

    // 🔥 GET ATTENDANCE OF STUDENT IN THESE CLASSES
    var attendanceSnapshot = await FirebaseFirestore.instance
        .collection("attendance")
        .where("studentId", isEqualTo: widget.studentId)
        .get();

    attended = attendanceSnapshot.docs.where((doc) {
      return classIds.contains(doc['classId']);
    }).length;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    int notAttended = totalClasses - attended;
    double percentage =
        totalClasses == 0 ? 0 : (attended / totalClasses) * 100;

    return Scaffold(
      appBar: AppBar(title: Text(widget.studentName)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Total Classes: $totalClasses",
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 10),

            Text("Attended: $attended",
                style: const TextStyle(fontSize: 20, color: Colors.green)),
            const SizedBox(height: 10),

            Text("Not Attended: $notAttended",
                style: const TextStyle(fontSize: 20, color: Colors.red)),
            const SizedBox(height: 20),

            Text(
              "Percentage: ${percentage.toStringAsFixed(2)}%",
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}