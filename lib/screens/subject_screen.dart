import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive for local offline caching
import '../services/gemini_service.dart';     // Import your custom Gemini service

class SubjectScreen extends StatelessWidget {
  const SubjectScreen({super.key});

  static const backgroundColor = Color(0xFF0D0D18);
  static const cardColor = Color(0xFF1A1A2E);
  static const primaryPurple = Color(0xFF534AB7);
  static const accentNeon = Color(0xFF5DCAA5);
  static const orangeWarn = Color(0xFFEF9F27);
  static const textPurple = Color(0xFFCECBF6);

  @override
  Widget build(BuildContext context) {
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
          int lectureCount = 0;
          int totalSlides = 0;
          List<DocumentSnapshot> lectureDocs = [];

          if (snapshot.hasData) {
            lectureDocs = snapshot.data!.docs;
            lectureCount = lectureDocs.length;
            for (var doc in lectureDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final String summary = data['summary'] ?? '';
              final match = RegExp(r'(\d+)\s+(?:slides|pages)').firstMatch(summary);
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
    
    // 1. INTERACTIVE FLASHCARD CARD
    GestureDetector(
      onTap: lectureDocs.isNotEmpty
          ? () {
              final latestDoc = lectureDocs.first;
              final latestData = latestDoc.data() as Map<String, dynamic>;
              Navigator.pushNamed(
                context,
                '/flashcards',
                arguments: {
                  'lectureId': latestDoc.id,
                  'lectureTitle': latestData['title'] ?? 'Lecture',
                },
              );
            }
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Upload a lecture first to generate flashcards!')),
              );
            },
      child: _buildStatCard(
        lectureDocs.isNotEmpty ? 'Review' : '0', 
        'Flashcards', 
        orangeWarn,
      ),
    ),
    
    // 2. INTERACTIVE WEAK SPOTS CARD WITH LIVE STREAM COUNT
    StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('weakspots')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_user')
          .snapshots(),
      builder: (context, weakSpotsSnapshot) {
        final int weakSpotsCount = weakSpotsSnapshot.hasData ? weakSpotsSnapshot.data!.docs.length : 0;

        return GestureDetector(
         onTap: () {
  Navigator.pushNamed(
    context,
    '/weakspots',
    arguments: {
      'subjectId': subjectId, // <-- Just change this from widget.subjectId to subjectId
    },
  );
},
          child: _buildStatCard(
            '$weakSpotsCount', 
            'Weak spots', 
            const Color(0xFFE24B4A),
          ),
        );
      },
    ),
  ],
),
                const SizedBox(height: 16),
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
                            Text('Study entire subject with AI',
                                style: TextStyle(color: Color(0xFFAFA9EC), fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(height: 2),
                            Text('Ask questions across all lectures',
                                style: TextStyle(color: primaryPurple, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.auto_awesome, color: primaryPurple, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'LECTURES',
                  style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),

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
                              Text('Upload new lecture',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
                            child: Text('L${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          title: Text(title,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                          subtitle: Text(summary, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/chat',
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

  Future<String> _extractTextViaHTTP(Uint8List fileBytes) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );

    final base64Pdf = base64Encode(fileBytes);

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": "Extract and transcribe all text content visible in this document. Do not summarize, just output the raw text found."},
            {
              "inline_data": {
                "mime_type": "application/pdf",
                "data": base64Pdf
              }
            }
          ]
        }
      ]
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
    }
    return '';
  }

  // INTEGRATED BACKGROUND TASK: Processes AI flashcards, writes to Hive box, commits to Firestore
  Future<void> _generateAndSaveFlashcardsBackground(String lectureId, String slideText) async {
    if (slideText.trim().isEmpty) return;
    
    final GeminiService geminiService = GeminiService();

    try {
      print("Starting background automated flashcard generation pipeline...");
      
      // 1. Fetch JSON string map via Gemini service instructions
      String jsonString = await geminiService.generateFlashcards(slideText);

      // 2. Save directly into a local box using lectureId as key
      var box = await Hive.openBox('flashcards');
      await box.put(lectureId, jsonString);

      // 3. Parse JSON array list payload items
      final List<dynamic> flashcardList = jsonDecode(jsonString);
      final firestore = FirebaseFirestore.instance;
      WriteBatch batch = firestore.batch();

      for (var card in flashcardList) {
        DocumentReference docRef = firestore.collection('flashcards').doc();
        batch.set(docRef, {
          'lectureId': lectureId,
          'question': card['question'] ?? 'No question text generated.',
          'answer': card['answer'] ?? 'No answer text generated.',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Execute batch network database storage write 
      await batch.commit();
      print("Flashcard cloud syncing pipeline completed successfully!");
    } catch (e) {
      print("Background flashcard generator execution failure error: $e");
    }
  }

  Future<void> _pickAndProcessPdf(BuildContext context, String subjectId) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) return;

      String fileName = result.files.single.name;
      Uint8List fileBytes = result.files.single.bytes!;

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: const AlertDialog(
            backgroundColor: Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: primaryPurple),
                SizedBox(height: 20),
                Text("Reading your slides...",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text("AI is scanning your document...",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
      );

      PdfDocument document = PdfDocument(inputBytes: fileBytes);
      String bigCombinedText = "";

      for (int i = 0; i < document.pages.count; i++) {
        String text = PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
        bigCombinedText += text;
      }
      int totalPagesCount = document.pages.count;
      document.dispose();

      if (bigCombinedText.trim().isEmpty) {
        bigCombinedText = await _extractTextViaHTTP(fileBytes);
      }

      // Save document data to firestore and grab the generated doc reference id
      DocumentReference lectureDocRef = await FirebaseFirestore.instance.collection('lectures').add({
        'subjectId': subjectId,
        'title': fileName.replaceAll('.pdf', ''),
        'summary': '$totalPagesCount pages processed',
        'pdfUrl': '',
        'slideText': bigCombinedText,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // TRIGGER FLASHCARD GENERATION CHAIN RIGHT HERE IN THE BACKGROUND
      // This will run asynchronously without making the user wait at the loading dialog!
      _generateAndSaveFlashcardsBackground(lectureDocRef.id, bigCombinedText);

      if (!context.mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lecture uploaded successfully! Flashcards generating...')),
      );
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
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