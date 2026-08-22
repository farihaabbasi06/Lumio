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
import 'dart:io';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

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



// Replace your entire _pickAndProcessPdf function with this
// No other changes needed in subject_screen.dart

Future<void> _pickAndProcessPdf(
    BuildContext context, String subjectId, AppColors colors) async {
  try {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc', 'txt', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) return;

    String fileName = result.files.single.name;
    Uint8List fileBytes = result.files.single.bytes!;
    String fileExtension = fileName.split('.').last.toLowerCase();

    // ── Professional size warning (not rejection) ──────────────────
    final fileSizeMB = fileBytes.length / (1024 * 1024);
    if (fileSizeMB > 25) {
      if (!context.mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: colors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Large File Detected',
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
          content: Text(
            'This file is ${fileSizeMB.toStringAsFixed(1)}MB. Processing may take 2-3 minutes. Continue?',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Continue',
                  style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    if (!context.mounted) return;

    // ── Progress state ─────────────────────────────────────────────
    final progressNotifier = ValueNotifier<String>('Preparing...');
    final pageNotifier = ValueNotifier<String>('');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: colors.card,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          content: ValueListenableBuilder<String>(
            valueListenable: progressNotifier,
            builder: (_, status, __) => ValueListenableBuilder<String>(
              valueListenable: pageNotifier,
              builder: (_, pageInfo, __) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: colors.primary),
                  const SizedBox(height: 20),
                  Text(
                    status,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  if (pageInfo.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      pageInfo,
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    fileExtension.toUpperCase(),
                    style: TextStyle(
                        color: colors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    String bigCombinedText = "";
    int totalPagesCount = 1;

    // ── PDF with page-by-page progress ────────────────────────────
    if (fileExtension == 'pdf') {
      progressNotifier.value = 'Opening PDF...';
      await Future.delayed(const Duration(milliseconds: 100));

      PdfDocument document = PdfDocument(inputBytes: fileBytes);
      totalPagesCount = document.pages.count;

      for (int i = 0; i < document.pages.count; i++) {
        // Update progress for every page
        pageNotifier.value = 'Reading page ${i + 1} of $totalPagesCount...';
        
        // Allow UI to update
        await Future.delayed(const Duration(milliseconds: 10));

        String text = PdfTextExtractor(document)
            .extractText(startPageIndex: i, endPageIndex: i);
        bigCombinedText += text;
      }

      document.dispose();

      // Fallback for image-based PDFs
      if (bigCombinedText.trim().isEmpty) {
        progressNotifier.value = 'Scanning image-based PDF...';
        pageNotifier.value = 'Using AI vision to read content';
        await Future.delayed(const Duration(milliseconds: 100));
        bigCombinedText = await _extractTextViaHTTP(fileBytes);
      }
    }

    // ── WORD ──────────────────────────────────────────────────────
    else if (fileExtension == 'docx' || fileExtension == 'doc') {
      progressNotifier.value = 'Reading Word document...';
      pageNotifier.value = 'Extracting all text content';
      await Future.delayed(const Duration(milliseconds: 200));
      try {
        bigCombinedText = docxToText(fileBytes);
        totalPagesCount = 1;
        if (bigCombinedText.trim().isEmpty) {
          bigCombinedText = "Word document uploaded but no readable text found.";
        }
      } catch (e) {
        bigCombinedText = "Error reading Word file: ${e.toString()}";
      }
    }

    // ── TXT ───────────────────────────────────────────────────────
    else if (fileExtension == 'txt') {
      progressNotifier.value = 'Reading text file...';
      pageNotifier.value = 'Loading content';
      await Future.delayed(const Duration(milliseconds: 200));
      try {
        bigCombinedText = String.fromCharCodes(fileBytes);
        totalPagesCount = 1;
      } catch (e) {
        bigCombinedText = "Error reading text file: ${e.toString()}";
      }
    }

    // ── IMAGES ────────────────────────────────────────────────────
    else if (fileExtension == 'jpg' ||
        fileExtension == 'jpeg' ||
        fileExtension == 'png') {
      progressNotifier.value = 'Scanning image with OCR...';
      pageNotifier.value = 'Reading text from image';
      await Future.delayed(const Duration(milliseconds: 200));
      try {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_image.$fileExtension');
        await tempFile.writeAsBytes(fileBytes);

        final inputImage = InputImage.fromFile(tempFile);
        final textRecognizer = TextRecognizer();
        final recognizedText = await textRecognizer.processImage(inputImage);
        await textRecognizer.close();

        bigCombinedText = recognizedText.text;
        totalPagesCount = 1;
        await tempFile.delete();

        if (bigCombinedText.trim().isEmpty) {
          bigCombinedText =
              "No text found in image. This may be a diagram or graph with no readable text.";
        }
      } catch (e) {
        bigCombinedText = "Error reading image: ${e.toString()}";
      }
    }

    // ── UNSUPPORTED ───────────────────────────────────────────────
    else {
      bigCombinedText = "Unsupported file format: $fileExtension";
    }

    // ── Save to Firestore ─────────────────────────────────────────
    progressNotifier.value = 'Saving to database...';
    pageNotifier.value = '$totalPagesCount page(s) extracted';
    await Future.delayed(const Duration(milliseconds: 100));

    final cleanTitle = fileName
        .replaceAll('.pdf', '')
        .replaceAll('.docx', '')
        .replaceAll('.doc', '')
        .replaceAll('.txt', '')
        .replaceAll('.jpg', '')
        .replaceAll('.jpeg', '')
        .replaceAll('.png', '');

    DocumentReference lectureDocRef =
        await FirebaseFirestore.instance.collection('lectures').add({
      'subjectId': subjectId,
      'userId': FirebaseAuth.instance.currentUser?.uid ?? '',
      'title': cleanTitle,
      'summary': '$totalPagesCount page(s) · ${fileExtension.toUpperCase()}',
      'pdfUrl': '',
      'slideText': bigCombinedText,
      'fileType': fileExtension,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ── Generate AI features ──────────────────────────────────────
    progressNotifier.value = 'Generating AI features...';
    pageNotifier.value = 'Creating flashcards, exam topics, mind map';
    await Future.delayed(const Duration(milliseconds: 100));

    await _generateAndSaveFlashcardsBackground(
      lectureDocRef.id,
      bigCombinedText,
      FirebaseAuth.instance.currentUser?.uid ?? '',
    );

    // ── Update subject progress ───────────────────────────────────
    final allLectures = await FirebaseFirestore.instance
        .collection('lectures')
        .where('subjectId', isEqualTo: subjectId)
        .get();
    final openedCount =
        allLectures.docs.where((d) => d.data()['opened'] == true).length;
    final total = allLectures.docs.length;
    final progress = total > 0 ? openedCount / total : 0.0;
    await FirebaseFirestore.instance
        .collection('subjects')
        .doc(subjectId)
        .update({'progress': progress});

    progressNotifier.dispose();
    pageNotifier.dispose();

    if (!context.mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${fileExtension.toUpperCase()} uploaded! $totalPagesCount page(s) processed.'),
        backgroundColor: const Color(0xFF1D9E75),
        duration: const Duration(seconds: 3),
      ),
    );
  } catch (e) {
    if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: colors.danger,
        ),
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