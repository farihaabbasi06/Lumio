import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';


class SubjectScreen extends StatelessWidget {
  const SubjectScreen({super.key});

  // Reusing your exact dark purple neon palette colors
  static const backgroundColor = Color(0xFF0D0D18);
  static const cardColor = Color(0xFF1A1A2E);
  static const primaryPurple = Color(0xFF534AB7);
  static const accentNeon = Color(0xFF5DCAA5);
  static const orangeWarn = Color(0xFFEF9F27);
  static const textPurple = Color(0xFFCECBF6);

  @override
  Widget build(BuildContext context) {
    // Catch arguments passed during navigation route changes
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String subjectId = args['subjectId'] ?? '';
    final String subjectName = args['subjectName'] ?? 'Subject View';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF131324),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          subjectName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lectures')
            .where('subjectId', isEqualTo: subjectId)
            .snapshots(),
        builder: (context, snapshot) {
          // Calculate dynamic statistics based on real-time stream state
          int lectureCount = 0;
          int totalSlides = 0;
          List<DocumentSnapshot> lectureDocs = [];

          if (snapshot.hasData) {
            lectureDocs = snapshot.data!.docs;
            lectureCount = lectureDocs.length;
            
            // Extract the slide counts safely from the description/summary fields
            for (var doc in lectureDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final String summary = data['summary'] ?? '';
              final match = RegExp(r'(\d+)\s+slides').firstMatch(summary);
              if (match != null) {
                totalSlides += int.parse(match.group(1)!);
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. STATS ROW - Updated to display dynamic database details
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.6,
                  children: [
                    _buildStatCard('$lectureCount', 'Lectures', primaryPurple),
                    _buildStatCard(totalSlides > 0 ? '$totalSlides' : '0', 'Slides', accentNeon),
                    _buildStatCard('0', 'Flashcards', orangeWarn),
                    _buildStatCard('0', 'Weak spots', const Color(0xFFE24B4A)),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. STUDY ENTIRE SUBJECT INTERACTIVE AI CARD
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1228),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF3C3489), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3C3489),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.psychology_outlined, color: textPurple),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Study entire subject with AI', style: TextStyle(color: Color(0xFFAFA9EC), fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(height: 2),
                            Text('Ask questions across all lectures', style: TextStyle(color: primaryPurple, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.auto_awesome, color: primaryPurple, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. LECTURES HEADER SECTION LABEL
                const Text(
                  'LECTURES',
                  style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),

                // 1. ADD UPLOAD LECTURE BUTTON
                GestureDetector(
                  onTap: () => _pickAndProcessPdf(context, subjectId),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2A2A3E), width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.upload_file_rounded, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Upload new lecture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              SizedBox(height: 2),
                              Text('PDF files up to 50MB', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. LECTURES LIST VIEW INTERACTION AREA
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator(color: primaryPurple))
                else if (lectureDocs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Text('No lectures uploaded yet.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: lectureDocs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final doc = lectureDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final String title = data['title'] ?? 'L${index + 1}';
                      final String summary = data['summary'] ?? 'No summary available';

                      return Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF252542),
                            foregroundColor: primaryPurple,
                            child: Text('L${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                          subtitle: Text(summary, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                          onTap: () {
                            // Route parameters forwarding down to the individual chat interface section next
                            Navigator.pushNamed(
                              context,
                              '/lecture-detail',
                              arguments: {
                                'lectureId': doc.id,
                                'lectureTitle': title,
                                'slideText': data['slideText'] ?? '',
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickAndProcessPdf(BuildContext context, String subjectId) async {
    try {
     // To this (static method call without .platform):
FilePickerResult? result = await FilePicker.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['pdf'],
  withData: true,
);

      if (result == null || result.files.single.path == null) return;

      String fileName = result.files.single.name;
      File file = File(result.files.single.path!);
      Uint8List? fileBytes = result.files.single.bytes ?? await file.readAsBytes();

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: const AlertDialog(
            backgroundColor: Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: primaryPurple),
                SizedBox(height: 20),
                Text("Reading your slides...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text("Extracting contents & archiving to cloud", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
      );

      Reference storageRef = FirebaseStorage.instance.ref().child('lectures/$subjectId/$fileName');
      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      PdfDocument document = PdfDocument(inputBytes: fileBytes);
      String bigCombinedText = "";

      for (int i = 0; i < document.pages.count; i++) {
        String text = PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
        bigCombinedText += text;
      }
      int totalPagesCount = document.pages.count;
      document.dispose();

      await FirebaseFirestore.instance.collection('lectures').add({
        'subjectId': subjectId,
        'title': fileName.replaceAll('.pdf', ''),
        'summary': '$totalPagesCount slides extracted successfully',
        'pdfUrl': downloadUrl,
        'slideText': bigCombinedText,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lecture added and indexed successfully!')),
      );

    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Widget _buildStatCard(String value, String label, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(color: accentColor, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}