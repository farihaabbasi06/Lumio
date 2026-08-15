import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExamSimSetupScreen extends StatefulWidget {
  const ExamSimSetupScreen({super.key});

  @override
  State<ExamSimSetupScreen> createState() => _ExamSimSetupScreenState();
}

class _ExamSimSetupScreenState extends State<ExamSimSetupScreen> {
  String _selectedFormat = 'Full Paper (MCQs + Short + Long)';
  int _selectedMinutes = 60;
  String? _selectedSubjectId;
  String? _selectedSubjectName;
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = false;

  static const backgroundColor = Color(0xFF0D0D18);
  static const cardColor = Color(0xFF1A1A2E);
  static const primaryPurple = Color(0xFF534AB7);
  static const accentNeon = Color(0xFF5DCAA5);

  final List<String> _formats = [
    'Full Paper (MCQs + Short + Long)',
    'MCQs Only',
    'Short Questions Only',
  ];

  final List<int> _durations = [30, 60, 90, 120, 180];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final snap = await FirebaseFirestore.instance
        .collection('subjects')
        .where('userId', isEqualTo: uid)
        .get();

    setState(() {
      _subjects = snap.docs
          .map((d) => {'id': d.id, 'name': d.data()['name'] ?? ''})
          .toList();
    });
  }

  Future<void> _startExam() async {
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Load all slide text from lectures in this subject
    final lectures = await FirebaseFirestore.instance
        .collection('lectures')
        .where('subjectId', isEqualTo: _selectedSubjectId)
        .get();

    String combinedSlideText = '';
    for (var doc in lectures.docs) {
      combinedSlideText += doc.data()['slideText'] ?? '';
    }

    if (combinedSlideText.trim().isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No lecture content found. Upload lectures first.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushNamed(
        context,
        '/exam-sim',
        arguments: {
          'slideText': combinedSlideText,
          'subjectName': _selectedSubjectName,
          'format': _selectedFormat,
          'durationMinutes': _selectedMinutes,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF131324),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('ExamSim',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1e1228), Color(0xFF0e1e16)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryPurple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_note_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Practice Exam',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        SizedBox(height: 2),
                        Text('AI generates a real exam from your lectures',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Select subject
            const Text('SELECT SUBJECT',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
            const SizedBox(height: 10),
            _subjects.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Text('No subjects found. Add subjects first.',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  )
                : Column(
                    children: _subjects.map((subject) {
                      final isSelected =
                          _selectedSubjectId == subject['id'];
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedSubjectId = subject['id'];
                          _selectedSubjectName = subject['name'];
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1e1228)
                                : cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? primaryPurple
                                  : Colors.transparent,
                              width: isSelected ? 1.5 : 0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? primaryPurple
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(subject['name'],
                                  style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey,
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 24),

            // Select format
            const Text('EXAM FORMAT',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Column(
              children: _formats.map((format) {
                final isSelected = _selectedFormat == format;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFormat = format),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1e1228)
                          : cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? primaryPurple : Colors.transparent,
                        width: isSelected ? 1.5 : 0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected ? primaryPurple : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(format,
                            style: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.grey,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Select duration
            const Text('TIME LIMIT',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _durations.map((mins) {
                  final isSelected = _selectedMinutes == mins;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMinutes = mins),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryPurple : cardColor,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: isSelected
                              ? primaryPurple
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        mins >= 60
                            ? '${mins ~/ 60}h${mins % 60 > 0 ? ' ${mins % 60}m' : ''}'
                            : '${mins}m',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 40),

            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isLoading ? null : _startExam,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Generate Exam Paper',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}