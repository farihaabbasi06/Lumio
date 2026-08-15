import 'package:flutter/material.dart';

class ExamSimResultScreen extends StatelessWidget {
  const ExamSimResultScreen({super.key});

  static const backgroundColor = Color(0xFF0D0D18);
  static const cardColor = Color(0xFF1A1A2E);
  static const primaryPurple = Color(0xFF534AB7);
  static const accentNeon = Color(0xFF5DCAA5);

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A+': case 'A': return const Color(0xFF5DCAA5);
      case 'B': return const Color(0xFF3A86FF);
      case 'C': return const Color(0xFFEF9F27);
      case 'D': return Colors.orange;
      default: return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final result = args['result'] as Map<String, dynamic>;
    final subjectName = args['subjectName'] ?? 'Exam';

    final int totalScore = result['total_score'] ?? 0;
    final int totalMax = result['total_max'] ?? 100;
    final int percentage = result['percentage'] ?? 0;
    final String grade = result['grade'] ?? 'F';
    final String feedback = result['overall_feedback'] ?? '';
    final int mcqScore = result['mcq_score'] ?? 0;
    final int mcqMax = result['mcq_max'] ?? 0;
    final int shortScore = result['short_score'] ?? 0;
    final int shortMax = result['short_max'] ?? 0;
    final int longScore = result['long_score'] ?? 0;
    final int longMax = result['long_max'] ?? 0;
    final mcqResults = List<Map<String, dynamic>>.from(result['mcq_results'] ?? []);
    final shortResults = List<Map<String, dynamic>>.from(result['short_results'] ?? []);
    final longResults = List<Map<String, dynamic>>.from(result['long_results'] ?? []);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF131324),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.grey),
          onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
        ),
        title: const Text('Exam Result', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // Result card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1e1228), _gradeColor(grade).withOpacity(0.15)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gradeColor(grade).withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Text(subjectName, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 12),
                  Text(grade,
                      style: TextStyle(
                          color: _gradeColor(grade),
                          fontSize: 64,
                          fontWeight: FontWeight.bold)),
                  Text('$percentage%', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('$totalScore / $totalMax marks', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Score breakdown
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('SCORE BREAKDOWN', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (mcqMax > 0) Expanded(child: _buildScoreCard('MCQs', mcqScore, mcqMax, primaryPurple)),
                if (mcqMax > 0) const SizedBox(width: 8),
                if (shortMax > 0) Expanded(child: _buildScoreCard('Short', shortScore, shortMax, accentNeon)),
                if (shortMax > 0) const SizedBox(width: 8),
                if (longMax > 0) Expanded(child: _buildScoreCard('Long', longScore, longMax, const Color(0xFFEF9F27))),
              ],
            ),
            const SizedBox(height: 20),

            // AI Feedback
            if (feedback.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('AI FEEDBACK', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primaryPurple.withOpacity(0.2)),
                ),
                child: Text(feedback, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.6)),
              ),
              const SizedBox(height: 20),
            ],

            // MCQ results
            if (mcqResults.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('MCQ RESULTS', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 10),
              ...mcqResults.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: r['is_correct'] == true ? accentNeon.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      r['is_correct'] == true ? Icons.check_circle : Icons.cancel,
                      color: r['is_correct'] == true ? accentNeon : Colors.redAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(r['question'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12))),
                    if (r['is_correct'] != true)
                      Text('Ans: ${r['correct_answer']}', style: const TextStyle(color: accentNeon, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
              const SizedBox(height: 20),
            ],

            // Short question results
            if (shortResults.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('SHORT QUESTION RESULTS', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 10),
              ...shortResults.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(r['question'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFF1e1228), borderRadius: BorderRadius.circular(6)),
                          child: Text('${r['marks_awarded']}/${r['max_marks']}', style: const TextStyle(color: accentNeon, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(r['feedback'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.5)),
                  ],
                ),
              )),
              const SizedBox(height: 20),
            ],

            // Long question results
            if (longResults.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('LONG QUESTION RESULTS', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 10),
              ...longResults.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(r['question'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFF1a1208), borderRadius: BorderRadius.circular(6)),
                          child: Text('${r['marks_awarded']}/${r['max_marks']}', style: const TextStyle(color: Color(0xFFEF9F27), fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(r['feedback'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.5)),
                  ],
                ),
              )),
            ],

            const SizedBox(height: 20),

            // Try again button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
                child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(String label, int score, int max, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text('$score/$max', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: max > 0 ? score / max : 0,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(color),
            borderRadius: BorderRadius.circular(99),
          ),
        ],
      ),
    );
  }
}