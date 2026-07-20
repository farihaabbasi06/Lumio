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
import 'package:hive_flutter/hive_flutter.dart';
import '../services/gemini_service.dart';
import '../widgets/app_widgets.dart';
import '../theme/app_colors.dart';

class SubjectScreen extends StatelessWidget {
  const SubjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String subjectId = args['subjectId'] ?? '';
    final String subjectName = args['subjectName'] ?? 'Subject View';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          subjectName,
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
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
                    _buildStatCard('$lectureCount', 'Lectures', Icons.play_circle_outline_rounded, colors.primary, colors),
                    _buildStatCard(totalSlides > 0 ? '$totalSlides' : '0', 'Slides', Icons.slideshow_rounded, colors.accent, colors),
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
                                  'subjectId': subjectId,
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
                        Icons.style_outlined,
                        colors.warning,
                        colors,
                      ),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('weakspots')
                          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_user')
                          .where('subjectId', isEqualTo: subjectId)
                          .snapshots(),
                      builder: (context, weakSpotsSnapshot) {
                        final int weakSpotsCount = weakSpotsSnapshot.hasData ? weakSpotsSnapshot.data!.docs.length : 0;

                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/weakspots',
                              arguments: {'subjectId': subjectId},
                            );
                          },
                          child: _buildStatCard('$weakSpotsCount', 'Weak spots', Icons.warning_amber_rounded, colors.danger, colors),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: lectureDocs.isNotEmpty
                      ? () {
                          final latestDoc = lectureDocs.first;
                          final latestData = latestDoc.data() as Map<String, dynamic>;
                          Navigator.pushNamed(
                            context,
                            '/mindmap',
                            arguments: {
                              'lectureId': latestDoc.id,
                              'subjectId': subjectId,
                              'lectureTitle': latestData['title'] ?? 'Lecture Mind Map',
                              'slideText': latestData['slideText'] ?? '',
                            },
                          );
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Upload a lecture first to view its mind map!')),
                          );
                        },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.primary.withAlpha(90), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.primary.withAlpha(60),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.psychology_outlined, color: colors.textPurple == Colors.white ? colors.primary : colors.textPurple),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Study entire subject with AI',
                                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('View interactive topic mind map clusters',
                                  style: TextStyle(color: colors.primary, fontSize: 11)),
                            ],
                          ),
                        ),
                        Icon(Icons.auto_awesome, color: colors.primary, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'LECTURES',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),

                GestureDetector(
                  onTap: () => _pickAndProcessPdf(context, subjectId, colors),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.inputFill,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.upload_file_rounded, color: colors.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Upload new lecture',
                                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('PDF files up to 50MB', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                if (snapshot.connectionState == ConnectionState.waiting)
                  Center(child: CircularProgressIndicator(color: colors.primary))
                else if (lectureDocs.isEmpty)
                  const LumioEmptyState(
                    icon: Icons.upload_file_rounded,
                    title: 'No lectures yet',
                    subtitle: 'Tap upload to add your first lecture PDF',
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

                      return GestureDetector(
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: colors.card,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Text('Delete Lecture',
                                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
                              content: Text(
                                'Delete "$title"? This cannot be undone.',
                                style: TextStyle(color: colors.textSecondary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await FirebaseFirestore.instance.collection('lectures').doc(doc.id).delete();
                                    await FirebaseFirestore.instance
                                        .collection('flashcards')
                                        .where('lectureId', isEqualTo: doc.id)
                                        .get()
                                        .then((snap) {
                                      for (var d in snap.docs) d.reference.delete();
                                    });
                                    await FirebaseFirestore.instance
                                        .collection('weakspots')
                                        .where('lectureId', isEqualTo: doc.id)
                                        .get()
                                        .then((snap) {
                                      for (var d in snap.docs) d.reference.delete();
                                    });
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Lecture deleted successfully'),
                                          backgroundColor: colors.danger,
                                        ),
                                      );
                                    }
                                  },
                                  child: Text('Delete', style: TextStyle(color: colors.danger, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: CircleAvatar(
                              backgroundColor: colors.inputFill,
                              foregroundColor: colors.primary,
                              child: Text('L${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            title: Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                            subtitle: Text(summary, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                            trailing: Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
                            onTap: () {
                              final String lectureContent = doc['slideText'] ?? '';
                              Navigator.pushNamed(
                                context,
                                '/lecture-detail',
                                arguments: {
                                  'lectureId': doc.id,
                                  'lectureTitle': title,
                                  'subjectId': subjectId,
                                  'slideText': lectureContent,
                                },
                              );
                            },
                          ),
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
    return '';
  }

  Future<void> _generateAndSaveFlashcardsBackground(String lectureId, String slideText, String userId) async {
    if (slideText.trim().isEmpty) return;

    final GeminiService geminiService = GeminiService();

    try {
      print("Starting background automated flashcard, prediction, and mindmap pipelines...");

      String flashcardsJson = await geminiService.generateFlashcards(slideText);
      String examPredictionsJson = await geminiService.predictExamTopics(slideText);
      String mindMapJson = await geminiService.generateMindMap(slideText);

      List<dynamic> examTopicsList = [];
      try {
        examTopicsList = jsonDecode(examPredictionsJson);
      } catch (e) {
        print("Error parsing exam topics JSON: $e");
      }

      List<dynamic> mindMapNodesList = [];
      try {
        mindMapNodesList = jsonDecode(mindMapJson);
      } catch (e) {
        print("Error parsing mind map JSON: $e");
      }

      await FirebaseFirestore.instance.collection('lectures').doc(lectureId).update({
        'flashcards': flashcardsJson,
        'examTopics': examTopicsList,
        'mindMapNodes': mindMapNodesList,
      });

      var box = await Hive.openBox('flashcards');
      await box.put(lectureId, flashcardsJson);

      final List<dynamic> flashcardList = jsonDecode(flashcardsJson);
      final firestore = FirebaseFirestore.instance;
      WriteBatch batch = firestore.batch();

      for (var card in flashcardList) {
        DocumentReference docRef = firestore.collection('flashcards').doc();
        batch.set(docRef, {
          'lectureId': lectureId,
          'userId': userId,
          'question': card['question'] ?? 'No question text generated.',
          'answer': card['answer'] ?? 'No answer text generated.',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print("AI Content sync pipelines (including Mind Map) completed successfully!");
    } catch (e) {
      print("Background content generator execution failure error: $e");
    }
  }

  Future<void> _pickAndProcessPdf(BuildContext context, String subjectId, AppColors colors) async {
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
          child: AlertDialog(
            backgroundColor: colors.card,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: colors.primary),
                const SizedBox(height: 20),
                Text("Reading your slides...",
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("AI is scanning your document...",
                    style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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

      DocumentReference lectureDocRef = await FirebaseFirestore.instance.collection('lectures').add({
        'subjectId': subjectId,
        'userId': FirebaseAuth.instance.currentUser?.uid ?? '',
        'title': fileName.replaceAll('.pdf', ''),
        'summary': '$totalPagesCount pages processed',
        'pdfUrl': '',
        'slideText': bigCombinedText,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _generateAndSaveFlashcardsBackground(
        lectureDocRef.id,
        bigCombinedText,
        FirebaseAuth.instance.currentUser?.uid ?? '',
      );

      if (!context.mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lecture uploaded successfully! AI features generated.')),
      );
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: colors.danger),
        );
      }
    }
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color accentColor, AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: accentColor, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}