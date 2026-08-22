import 'dart:async';
import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

class ExamSimScreen extends StatefulWidget {
  const ExamSimScreen({super.key});

  @override
  State<ExamSimScreen> createState() => _ExamSimScreenState();
}

class _ExamSimScreenState extends State<ExamSimScreen> {
  final GeminiService _geminiService = GeminiService();
  bool _isGenerating = true;
  Map<String, dynamic> _paper = {};

  List<String> _mcqAnswers = [];
  List<TextEditingController> _shortControllers = [];
  List<TextEditingController> _longControllers = [];

  late Timer _timer;
  int _secondsLeft = 3600;
  int _currentSection = 0;

  // FIX 1 — track which sections to show based on format
  bool _showMCQs = true;
  bool _showShort = true;
  bool _showLong = true;

  static const backgroundColor = Color(0xFF0D0D18);
  static const cardColor = Color(0xFF1A1A2E);
  static const primaryPurple = Color(0xFF534AB7);

  late String _slideText;
  late String _format;
  late String _subjectName;
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _slideText = args['slideText'] ?? '';
    _format = args['format'] ?? 'Full Paper (MCQs + Short + Long)';
    _subjectName = args['subjectName'] ?? 'Subject';
    _secondsLeft = (args['durationMinutes'] ?? 60) * 60;

    // FIX 1 — set which sections to show based on selected format
    if (_format == 'MCQs Only') {
      _showMCQs = true;
      _showShort = false;
      _showLong = false;
    } else if (_format == 'Short Questions Only') {
      _showMCQs = false;
      _showShort = true;
      _showLong = false;
    } else {
      // Full Paper
      _showMCQs = true;
      _showShort = true;
      _showLong = true;
    }

    _generatePaper();
  }

  Future<void> _generatePaper() async {
    final paper = await _geminiService.generateExamPaper(
      _slideText,
      _format,
    );

    if (mounted) {
      // FIX 1 — only load sections that match the format
      final mcqs = _showMCQs
          ? List<Map<String, dynamic>>.from(paper['mcqs'] ?? [])
          : <Map<String, dynamic>>[];
      final shortQs = _showShort
          ? List<Map<String, dynamic>>.from(paper['short_questions'] ?? [])
          : <Map<String, dynamic>>[];
      final longQs = _showLong
          ? List<Map<String, dynamic>>.from(paper['long_questions'] ?? [])
          : <Map<String, dynamic>>[];

      // Store filtered paper
      final filteredPaper = {
        'mcqs': mcqs,
        'short_questions': shortQs,
        'long_questions': longQs,
      };

      setState(() {
        _paper = filteredPaper;
        _mcqAnswers = List.filled(mcqs.length, '');
        _shortControllers = List.generate(shortQs.length, (_) => TextEditingController());
        _longControllers = List.generate(longQs.length, (_) => TextEditingController());
        _isGenerating = false;

        // Set starting section to first available
        if (_showMCQs) {
          _currentSection = 0;
        } else if (_showShort) {
          _currentSection = 1;
        } else {
          _currentSection = 2;
        }
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
        _submitExam();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _timerDisplay {
    final h = _secondsLeft ~/ 3600;
    final m = (_secondsLeft % 3600) ~/ 60;
    final s = _secondsLeft % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_secondsLeft < 300) return Colors.redAccent;
    if (_secondsLeft < 600) return Colors.orange;
    return const Color(0xFF5DCAA5);
  }

  Future<void> _submitExam() async {
    if (_timer.isActive) _timer.cancel();

    // FIX 2 — warn if MCQs were not answered
    final mcqs = List<Map<String, dynamic>>.from(_paper['mcqs'] ?? []);
    final unansweredMCQs = _mcqAnswers.where((a) => a.isEmpty).length;

    if (_showMCQs && unansweredMCQs > 0 && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Unanswered MCQs',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            'You have $unansweredMCQs unanswered MCQ(s). Unanswered MCQs will be marked as wrong (0 marks). Continue?',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Go Back', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit Anyway',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF534AB7)),
            SizedBox(height: 16),
            Text('AI is grading your answers...',
                style: TextStyle(color: Colors.white)),
            SizedBox(height: 4),
            Text('This may take 20-30 seconds',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );

    final shortQs = List<Map<String, dynamic>>.from(_paper['short_questions'] ?? []);
    final longQs = List<Map<String, dynamic>>.from(_paper['long_questions'] ?? []);

    // FIX 3 — wrap grading in try/catch for internet loss
    Map<String, dynamic> result;
    try {
      result = await _geminiService.gradeExamAnswers(
        slideText: _slideText,
        mcqs: mcqs,
        mcqAnswers: _mcqAnswers,
        shortQuestions: shortQs,
        shortAnswers: _shortControllers.map((c) => c.text).toList(),
        longQuestions: longQs,
        longAnswers: _longControllers.map((c) => c.text).toList(),
      );

      // FIX 3 — if result has error, show clean message
      if (result['overall_feedback']?.toString().contains('error') == true ||
          result['overall_feedback']?.toString().contains('Error') == true) {
        result['overall_feedback'] =
            'Grading could not be completed due to a connection issue. MCQ scores are still accurate. Please check your internet and try again.';
      }
    } catch (e) {
      // FIX 3 — internet lost — still show MCQ results at least
      int mcqScore = 0;
      List<Map<String, dynamic>> mcqResults = [];
      for (int i = 0; i < mcqs.length; i++) {
        final correct = mcqs[i]['correct']?.toString() ?? '';
        final userAnswer = i < _mcqAnswers.length ? _mcqAnswers[i] : '';
        final isCorrect = userAnswer.isNotEmpty &&
            correct.isNotEmpty &&
            userAnswer.toUpperCase()[0] == correct.toUpperCase()[0];
        if (isCorrect) mcqScore++;
        mcqResults.add({
          'question': mcqs[i]['question'],
          'user_answer': userAnswer,
          'correct_answer': correct,
          'is_correct': isCorrect,
        });
      }

      result = {
        'mcq_results': mcqResults,
        'mcq_score': mcqScore,
        'mcq_max': mcqs.length,
        'short_results': [],
        'short_score': 0,
        'short_max': shortQs.length * 5,
        'long_results': [],
        'long_score': 0,
        'long_max': longQs.length * 10,
        'total_score': mcqScore,
        'total_max': mcqs.length + (shortQs.length * 5) + (longQs.length * 10),
        'percentage': mcqs.isEmpty ? 0 : (mcqScore / mcqs.length * 100).round(),
        'overall_feedback':
            'AI grading failed due to internet connection. Your MCQ results are shown accurately. Short and long question grading requires internet — please retry.',
        'grade': mcqs.isEmpty ? 'F' : _getGrade(mcqScore, mcqs.length),
      };
    }

    if (mounted) {
      Navigator.pop(context);
      Navigator.pushReplacementNamed(
        context,
        '/exam-sim-result',
        arguments: {
          'result': result,
          'subjectName': _subjectName,
          'paper': _paper,
        },
      );
    }
  }

  String _getGrade(int score, int max) {
    if (max == 0) return 'F';
    final p = (score / max * 100).round();
    if (p >= 90) return 'A+';
    if (p >= 80) return 'A';
    if (p >= 70) return 'B';
    if (p >= 60) return 'C';
    if (p >= 50) return 'D';
    return 'F';
  }

  @override
  void dispose() {
    if (_timer.isActive) _timer.cancel();
    for (var c in _shortControllers) c.dispose();
    for (var c in _longControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mcqs = List<Map<String, dynamic>>.from(_paper['mcqs'] ?? []);
    final shortQs = List<Map<String, dynamic>>.from(_paper['short_questions'] ?? []);
    final longQs = List<Map<String, dynamic>>.from(_paper['long_questions'] ?? []);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF131324),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(_subjectName,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: _timerColor, width: 0.5),
            ),
            child: Text(_timerDisplay,
                style: TextStyle(
                    color: _timerColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'monospace')),
          ),
          TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: cardColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('Submit Exam?',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                content: const Text(
                    'Are you sure you want to submit? This cannot be undone.',
                    style: TextStyle(color: Colors.grey)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.grey))),
                  TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _submitExam();
                      },
                      child: const Text('Submit',
                          style: TextStyle(
                              color: primaryPurple,
                              fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            child: const Text('Submit',
                style: TextStyle(
                    color: primaryPurple, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isGenerating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryPurple, strokeWidth: 2),
                  SizedBox(height: 16),
                  Text('AI is generating your exam paper...',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  SizedBox(height: 6),
                  Text('This takes about 15 seconds',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
          : Column(
              children: [
                // FIX 1 — only show tabs for selected format
                Container(
                  color: const Color(0xFF131324),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      if (_showMCQs && mcqs.isNotEmpty)
                        _buildSectionTab(0, 'MCQs (${mcqs.length})', Icons.check_circle_outline),
                      if (_showShort && shortQs.isNotEmpty)
                        _buildSectionTab(1, 'Short (${shortQs.length})', Icons.short_text),
                      if (_showLong && longQs.isNotEmpty)
                        _buildSectionTab(2, 'Long (${longQs.length})', Icons.notes),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_currentSection == 0 && _showMCQs && mcqs.isNotEmpty)
                          ...List.generate(mcqs.length, (i) => _buildMCQ(i, mcqs[i])),
                        if (_currentSection == 1 && _showShort && shortQs.isNotEmpty)
                          ...List.generate(shortQs.length, (i) => _buildShortQuestion(i, shortQs[i])),
                        if (_currentSection == 2 && _showLong && longQs.isNotEmpty)
                          ...List.generate(longQs.length, (i) => _buildLongQuestion(i, longQs[i])),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTab(int index, String label, IconData icon) {
    final isActive = _currentSection == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentSection = index),
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? primaryPurple : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isActive ? Colors.white : Colors.grey),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMCQ(int index, Map<String, dynamic> mcq) {
    final options = List<String>.from(mcq['options'] ?? []);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration:
          BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Q${index + 1}. ${mcq['question']}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          ...options.map((opt) {
            final optionLetter = opt.isNotEmpty ? opt[0] : '';
            final isSelected = _mcqAnswers[index] == optionLetter;
            return GestureDetector(
              onTap: () => setState(() => _mcqAnswers[index] = optionLetter),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1e1228)
                      : const Color(0xFF0D0D18),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                      color: isSelected ? primaryPurple : Colors.transparent,
                      width: isSelected ? 1.5 : 0),
                ),
                child: Text(opt,
                    style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontSize: 12)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildShortQuestion(int index, Map<String, dynamic> q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration:
          BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('Q${index + 1}. ${q['question']}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFF1e1228),
                    borderRadius: BorderRadius.circular(6)),
                child: Text('${q['marks']} marks',
                    style: const TextStyle(
                        color: Color(0xFF5DCAA5), fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _shortControllers[index],
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Write your answer here...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF0D0D18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLongQuestion(int index, Map<String, dynamic> q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration:
          BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('Q${index + 1}. ${q['question']}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFF1a1208),
                    borderRadius: BorderRadius.circular(6)),
                child: Text('${q['marks']} marks',
                    style: const TextStyle(
                        color: Color(0xFFEF9F27), fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _longControllers[index],
            maxLines: 8,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Write your detailed answer here...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF0D0D18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}