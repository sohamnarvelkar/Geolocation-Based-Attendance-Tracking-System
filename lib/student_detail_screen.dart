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
  bool isLoading = true; // Added loading state for smoother UI

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

    setState(() {
      isLoading = false; // Data fetched, update UI
    });
  }

  // Helper widget for clean, modern stat cards
  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6F9A73), // lightGreen
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
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
    const Color beigeAccent = Color(0xFFE2CFA9);

    int notAttended = totalClasses - attended;
    double percentage = totalClasses == 0 ? 0 : (attended / totalClasses) * 100;

    // Convert percentage to a 0.0 - 1.0 scale for the progress bar
    double progressValue = totalClasses == 0 ? 0 : (attended / totalClasses);

    // Determine health color based on 75% threshold
    Color healthColor = percentage >= 75 ? primaryGreen : warningRed;

    return Scaffold(
      backgroundColor: offWhiteBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Student Report",
          style: TextStyle(color: darkText, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: darkText),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- STUDENT HEADER ---
                  Center(
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: beigeAccent.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.studentName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Overall Attendance",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: lightGreen),
                  ),
                  const SizedBox(height: 40),

                  // --- HORIZONTAL LINEAR GRAPH ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Completion",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: darkText,
                              ),
                            ),
                            Text(
                              "${percentage.toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: healthColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Custom Thick Progress Bar
                        Container(
                          height: 24,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: warningRed.withOpacity(
                              0.15,
                            ), // Background track acts as 'Missed'
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  width: constraints.maxWidth * progressValue,
                                  decoration: BoxDecoration(
                                    color: healthColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: primaryGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  "Attended",
                                  style: TextStyle(
                                    color: lightGreen,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: warningRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  "Missed",
                                  style: TextStyle(
                                    color: lightGreen,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- STATS GRID ---
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildStatCard(
                        "Attended",
                        attended.toString(),
                        primaryGreen,
                        Icons.check_circle_outline_rounded,
                      ),
                      _buildStatCard(
                        "Missed",
                        notAttended.toString(),
                        warningRed,
                        Icons.cancel_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Total Classes Card (Spans full width at bottom)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryGreen.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Classes Held",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        Text(
                          totalClasses.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
