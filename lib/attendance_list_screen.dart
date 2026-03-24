import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceListScreen extends StatelessWidget {
  final String classId;
  final String subject;
  final DateTime startTime;
  final DateTime endTime;

  const AttendanceListScreen({
    super.key,
    required this.classId,
    required this.subject,
    required this.startTime,
    required this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Attendance - $subject")),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ ONLY FILTER BY classId (NO index error)
        stream: FirebaseFirestore.instance
            .collection("attendance")
            .where("classId", isEqualTo: classId)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No attendance found"));
          }

          // 🔥 FILTER BY TIME IN APP (BEST SOLUTION)
          var docs = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;

            if (data['time'] == null) return false;

            DateTime time = data['time'].toDate();

            return time.isAfter(startTime) && time.isBefore(endTime);
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text("No students in this session"));
          }

          return Column(
            children: [
              // 🔥 TOTAL COUNT
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  "Total Students: ${docs.length}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Divider(),

              // 🔥 STUDENT LIST
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;

                    String name = data['studentName'] ?? "Unknown";
                    String email = data['studentEmail'] ?? "N/A";

                    String time = data['time'] != null
                        ? data['time'].toDate().toString()
                        : "No time";

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(name),
                        subtitle: Text("Email: $email\nTime: $time"),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
