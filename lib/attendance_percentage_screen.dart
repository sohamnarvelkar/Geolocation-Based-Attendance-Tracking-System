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
  bool isLoading = true;

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
      isLoading = false; // Data loaded, stop showing loader
    });
  }

  // Helper widget to build the stats cards
  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6F9A73), // lightGreen
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
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
    const Color warningRed = Color(0xFFD9534F);

    int notAttended = totalClasses - attendedClasses;
    double percentage = totalClasses == 0
        ? 0
        : (attendedClasses / totalClasses) * 100;
        
    // Value between 0.0 and 1.0 for the progress indicator
    double progressValue = totalClasses == 0 ? 0 : (attendedClasses / totalClasses);

    return Scaffold(
      backgroundColor: offWhiteBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Overall Attendance",
          style: TextStyle(color: darkText, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: darkText),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryGreen))
        : SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // 🔥 THE CIRCULAR GRAPH
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 220,
                        width: 220,
                        child: CircularProgressIndicator(
                          value: progressValue,
                          strokeWidth: 20,
                          backgroundColor: Colors.white,
                          color: percentage >= 75 ? primaryGreen : warningRed,
                          strokeCap: StrokeCap.round, // Modern rounded edges
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            "${percentage.toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: percentage >= 75 ? primaryGreen : warningRed,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Attended",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: lightGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Status message based on percentage
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: percentage >= 75 
                          ? primaryGreen.withOpacity(0.1) 
                          : warningRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      percentage >= 75 
                          ? "Great job! You are above the 75% requirement. 🎉"
                          : "Warning: Your attendance is below 75%. ⚠️",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: percentage >= 75 ? primaryGreen : warningRed,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Stats Cards
                  _buildStatCard(
                    "Total Classes", 
                    totalClasses.toString(), 
                    darkText, 
                    Icons.class_rounded
                  ),
                  const SizedBox(height: 16),
                  
                  _buildStatCard(
                    "Classes Attended", 
                    attendedClasses.toString(), 
                    primaryGreen, 
                    Icons.check_circle_rounded
                  ),
                  const SizedBox(height: 16),
                  
                  _buildStatCard(
                    "Classes Missed", 
                    notAttended.toString(), 
                    warningRed, 
                    Icons.cancel_rounded
                  ),
                ],
              ),
            ),
          ),
    );
  }
}