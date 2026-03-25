import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'attendance_list_screen.dart';

class PastClassesScreen extends StatelessWidget {
  const PastClassesScreen({super.key});

  // Helper function to format dates cleanly
  String _formatDate(DateTime dt) {
    String day = dt.day.toString().padLeft(2, '0');
    String month = dt.month.toString().padLeft(2, '0');
    String year = dt.year.toString();
    String hour = dt.hour.toString().padLeft(2, '0');
    String minute = dt.minute.toString().padLeft(2, '0');
    return "$day/$month/$year  •  $hour:$minute";
  }

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
          "Past Classes",
          style: TextStyle(color: darkText, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: darkText),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("classes")
            .orderBy("startTime", descending: true) // 🔥 correct field
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 80, color: beigeAccent),
                  const SizedBox(height: 16),
                  const Text(
                    "No Past Classes",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Your class history will appear here.",
                    style: TextStyle(color: lightGreen),
                  ),
                ],
              ),
            );
          }

          final classes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              var data = classes[index];

              String subject = data['subject'] ?? "No Subject";
              String classId = data['classId'];

              DateTime startTime = (data['startTime'] as Timestamp).toDate();

              DateTime endTime = data['endTime'] != null
                  ? (data['endTime'] as Timestamp).toDate()
                  : DateTime.now(); // fallback

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
                      Icons.event_note_rounded,
                      color: primaryGreen,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.play_circle_outline_rounded,
                              size: 14,
                              color: lightGreen,
                            ),
                            const SizedBox(width: 6),
                            // 🔥 FIXED: Wrapped Text in Expanded
                            Expanded(
                              child: Text(
                                "Started: ${_formatDate(startTime)}",
                                style: const TextStyle(
                                  color: lightGreen,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.stop_circle_outlined,
                              size: 14,
                              color: Color(0xFFD9534F),
                            ),
                            const SizedBox(width: 6),
                            // 🔥 FIXED: Wrapped Text in Expanded
                            Expanded(
                              child: Text(
                                "Ended: ${_formatDate(endTime)}",
                                style: const TextStyle(
                                  color: lightGreen,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: offWhiteBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: primaryGreen,
                    ),
                  ),

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
