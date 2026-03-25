import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  // Helper function for UI date formatting
  String _formatDate(DateTime dt) {
    String day = dt.day.toString().padLeft(2, '0');
    String month = dt.month.toString().padLeft(2, '0');
    String year = dt.year.toString();
    String hour = dt.hour.toString().padLeft(2, '0');
    String minute = dt.minute.toString().padLeft(2, '0');
    return "$day/$month/$year - $hour:$minute";
  }

  // 🔥 PDF GENERATOR
  Future<void> generatePDF(List docs) async {
    final pdf = pw.Document();

    String now = DateTime.now().toString().split(
      '.',
    )[0]; // Clean up the current time
    String formattedStartTime = _formatDate(startTime);
    String formattedEndTime = _formatDate(endTime);

    // Prepare table data
    final List<List<String>> tableData = [
      ['Sr No.', 'Email'], // Table Header
    ];

    // Populate table rows
    for (int i = 0; i < docs.length; i++) {
      var data = docs[i].data() as Map<String, dynamic>;
      String email = data['studentEmail'] ?? "N/A";
      tableData.add([(i + 1).toString(), email]);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header remains the same
              pw.Text(
                "Attendance Report",
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Text("Subject: $subject", style: pw.TextStyle(fontSize: 14)),
              pw.Text(
                "Start Time: $formattedStartTime",
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                "End Time: $formattedEndTime",
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                "Generated At: $now",
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),

              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),

              pw.Text(
                "Student Attendance List",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 15),

              // 🔥 NEW TABLE FORMAT
              pw.TableHelper.fromTextArray(
                context: context,
                data: tableData,
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                headerHeight: 30,
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.center, // Center the Sr No.
                  1: pw.Alignment.centerLeft, // Left align the email
                },
                columnWidths: {
                  0: const pw.FixedColumnWidth(60), // Fixed width for Sr No.
                  1: const pw.FlexColumnWidth(), // Email takes remaining space
                },
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
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
        title: Text(
          "Attendance - $subject",
          style: const TextStyle(color: darkText, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: darkText),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("attendance")
            .where("classId", isEqualTo: classId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          }

          var docs = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;

            if (data['time'] == null) return false;

            DateTime time = data['time'].toDate();

            return time.isAfter(startTime) && time.isBefore(endTime);
          }).toList();

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off_rounded, size: 80, color: beigeAccent),
                  const SizedBox(height: 16),
                  const Text(
                    "No students present",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Dashboard Header Section
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total Students",
                          style: TextStyle(fontSize: 14, color: lightGreen),
                        ),
                        Text(
                          "${docs.length}",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    // 🔥 MODERN PDF BUTTON
                    ElevatedButton.icon(
                      onPressed: () => generatePDF(docs),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text("Export PDF"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1),

              // Student List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;

                    String name = data['studentName'] ?? "Unknown";
                    String email = data['studentEmail'] ?? "N/A";

                    if (name == email) {
                      name = email.split('@')[0];
                    }

                    DateTime rawTime = data['time'].toDate();
                    String time =
                        "${rawTime.hour}:${rawTime.minute.toString().padLeft(2, '0')}";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: primaryGreen,
                          ),
                        ),
                        // 🔥 SHOW NAME AND TIME ONLY
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: offWhiteBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            time,
                            style: const TextStyle(
                              color: lightGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
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
