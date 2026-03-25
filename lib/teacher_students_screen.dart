import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_detail_screen.dart';

class TeacherStudentsScreen extends StatelessWidget {
  final String teacherName;

  const TeacherStudentsScreen({super.key, required this.teacherName});

  @override
  Widget build(BuildContext context) {
    // Local color variables for the theme
    const Color primaryGreen = Color(0xFF3E6B4A);
    const Color lightGreen = Color(0xFF6F9A73);
    const Color offWhiteBackground = Color(0xFFF9F1DF);
    const Color darkText = Color(0xFF2A3B2F);
    const Color beigeAccent = Color(0xFFE2CFA9);

    return Scaffold(
      backgroundColor: offWhiteBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Students",
          style: TextStyle(color: darkText, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: darkText),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          }

          // 🔥 FILTER ONLY STUDENTS
          var students = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return data['role'] == 'student';
          }).toList();

          if (students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off_rounded, size: 80, color: beigeAccent),
                  const SizedBox(height: 16),
                  const Text(
                    "No Students Found",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Registered students will appear here.",
                    style: TextStyle(color: lightGreen),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              var data = students[index].data() as Map<String, dynamic>;

              String name = data['name'] ?? "No Name";
              String email = data['email'] ?? "No Email";
              String studentId = students[index].id;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: beigeAccent.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: primaryGreen,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: lightGreen,
                      ),
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: offWhiteBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.chevron_right_rounded, color: primaryGreen),
                  ),
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