import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'attendance_list_screen.dart';

class PastClassesScreen extends StatelessWidget {
  const PastClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Past Attendance")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("classes")
            .orderBy("startTime", descending: true) // 🔥 correct field
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No past classes found 📭"));
          }

          final classes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: classes.length,
            itemBuilder: (context, index) {
              var data = classes[index];

              String subject = data['subject'] ?? "No Subject";
              String classId = data['classId'];

              DateTime startTime = (data['startTime'] as Timestamp).toDate();

              DateTime endTime = data['endTime'] != null
                  ? (data['endTime'] as Timestamp).toDate()
                  : DateTime.now(); // fallback

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.class_),
                  title: Text(subject),
                  subtitle: Text("Start: $startTime\nEnd: $endTime"),
                  trailing: const Icon(Icons.arrow_forward),

                  // 🔥 OPEN ATTENDANCE LIST
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AttendanceListScreen(
                          classId: classId,
                          subject: subject,
                          startTime: startTime,
                          endTime: endTime,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
