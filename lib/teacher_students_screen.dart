import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_detail_screen.dart';

class TeacherStudentsScreen extends StatelessWidget {
  final String teacherName;

  const TeacherStudentsScreen({super.key, required this.teacherName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Students")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // 🔥 FILTER ONLY STUDENTS
          var students = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return data['role'] == 'student';
          }).toList();

          if (students.isEmpty) {
            return const Center(child: Text("No Students Found"));
          }

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              var data = students[index].data() as Map<String, dynamic>;

              String name = data['name'] ?? "No Name";
              String email = data['email'] ?? "No Email";
              String studentId = students[index].id;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(name),
                  subtitle: Text(email),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentDetailScreen(
                          studentId: studentId,
                          studentName: name,
                          teacherName: teacherName,
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