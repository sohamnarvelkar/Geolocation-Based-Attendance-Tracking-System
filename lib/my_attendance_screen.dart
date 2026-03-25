import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyAttendanceScreen extends StatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    String studentId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("My Attendance")),
      body: Column(
        children: [
          // 📅 DATE PICKER
          Padding(
            padding: const EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );

                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
              child: Text(
                "Select Date: ${selectedDate.toLocal().toString().split(' ')[0]}",
              ),
            ),
          ),

          const Divider(),

          // 📊 ATTENDANCE LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("attendance")
                  .where("studentId", isEqualTo: studentId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;

                  if (data['time'] == null) return false;

                  DateTime time = data['time'].toDate();

                  return time.year == selectedDate.year &&
                      time.month == selectedDate.month &&
                      time.day == selectedDate.day;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("No Attendance Found 📭"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;

                    DateTime time = data['time'].toDate();

                    // 🔥 FETCH SUBJECT FROM CLASSES
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection("classes")
                          .doc(data['classId'])
                          .get(),
                      builder: (context, classSnapshot) {
                        String subject = "Loading...";

                        if (classSnapshot.hasData &&
                            classSnapshot.data!.exists) {
                          var classData = classSnapshot.data!.data()
                              as Map<String, dynamic>;
                          subject = classData['subject'] ?? "No Subject";
                        }

                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            leading: const Icon(Icons.check_circle,
                                color: Colors.green),
                            title: Text(subject), // ✅ SUBJECT HERE
                            subtitle: Text("Time: $time"),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}