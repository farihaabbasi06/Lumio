import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static const int dailyLimit = 50;
  static int _currentGroqKeyIndex = 0;

  // ─── LOAD GROQ KEYS ───────────────────────────────────────────────
  List<String> _loadGroqKeys() {
    final keys = <String>[];
    for (int i = 1; i <= 5; i++) {
      final k = dotenv.env['GROQ_API_KEY_$i'] ?? '';
      if (k.trim().isNotEmpty) keys.add(k.trim());
    }
    if (keys.isEmpty) {
      final legacy = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (legacy.trim().isNotEmpty) keys.add(legacy.trim());
    }
    return keys;
  }

  // ─── CALL GROQ ────────────────────────────────────────────────────
  Future<String?> _tryGroq(String prompt, int maxTokens) async {
    final keys = _loadGroqKeys();
    if (keys.isEmpty) return null;

    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final body = jsonEncode({
      "model": "llama-3.1-8b-instant",
      "messages": [
        {"role": "user", "content": prompt}
      ],
      "temperature": 0.7,
      "max_tokens": maxTokens,
    });

    for (int attempt = 0; attempt < keys.length; attempt++) {
      final keyIndex = (_currentGroqKeyIndex + attempt) % keys.length;
      final apiKey = keys[keyIndex];

      try {
        final response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $apiKey",
          },
          body: body,
        );

        if (response.statusCode == 200) {
          _currentGroqKeyIndex = keyIndex;
          final data = jsonDecode(response.body);
          return data['choices']?[0]?['message']?['content'];
        }

        if (response.statusCode == 429 || response.statusCode == 401) {
          debugPrint('Groq key #${keyIndex + 1} failed, trying next...');
          continue;
        }

        return null;
      } catch (e) {
        continue;
      }
    }
    return null; // all Groq keys exhausted
  }

  // ─── CALL COHERE ──────────────────────────────────────────────────
  Future<String?> _tryCohere(String prompt, int maxTokens) async {
    final apiKey = dotenv.env['COHERE_API_KEY'] ?? '';
    if (apiKey.isEmpty) return null;

    try {
      final url = Uri.parse('https://api.cohere.com/v2/chat');
final body = jsonEncode({
  "model": "command-r",
  "messages": [
    {"role": "user", "content": prompt}
  ],
  "max_tokens": maxTokens,
});

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['message']?['content']?[0]?['text']?.toString().trim();
        debugPrint('Cohere responded successfully');
        return text;
      }

      debugPrint('Cohere failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Cohere error: $e');
      return null;
    }
  }

  // ─── CALL MISTRAL ─────────────────────────────────────────────────
  Future<String?> _tryMistral(String prompt, int maxTokens) async {
    final apiKey = dotenv.env['MISTRAL_API_KEY'] ?? '';
    if (apiKey.isEmpty) return null;

    try {
      final url =
          Uri.parse('https://api.mistral.ai/v1/chat/completions');
      final body = jsonEncode({
        "model": "mistral-small-latest",
        "messages": [
          {"role": "user", "content": prompt}
        ],
        "temperature": 0.7,
        "max_tokens": maxTokens,
      });

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content']?.toString().trim();
        debugPrint('Mistral responded successfully');
        return text;
      }

      debugPrint('Mistral failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Mistral error: $e');
      return null;
    }
  }

  // ─── MASTER API CALL — tries Groq → Cohere → Mistral ─────────────
  Future<String> _callAPI(String prompt, {int maxTokens = 1024}) async {
    // 1. Try all Groq keys first
    final groqResult = await _tryGroq(prompt, maxTokens);
    if (groqResult != null && groqResult.isNotEmpty) return groqResult;

    debugPrint('All Groq keys exhausted — trying Cohere...');

    // 2. Try Cohere
    final cohereResult = await _tryCohere(prompt, maxTokens);
    if (cohereResult != null && cohereResult.isNotEmpty) return cohereResult;

    debugPrint('Cohere exhausted — trying Mistral...');

    // 3. Try Mistral
    final mistralResult = await _tryMistral(prompt, maxTokens);
    if (mistralResult != null && mistralResult.isNotEmpty) return mistralResult;

    // All platforms exhausted
    return "API Error: All AI services are currently unavailable. Please try again in a few minutes.";
  }

  // ─── DAILY LIMIT ──────────────────────────────────────────────────
  Future<int> getTodayCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString('question_date') ?? '';
    if (savedDate != today) {
      await prefs.setString('question_date', today);
      await prefs.setInt('question_count', 0);
      return 0;
    }
    return prefs.getInt('question_count') ?? 0;
  }

  Future<void> incrementCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('question_count') ?? 0;
    await prefs.setInt('question_count', current + 1);
  }

  Future<int> questionsRemaining() async {
    final count = await getTodayCount();
    return (dailyLimit - count).clamp(0, dailyLimit);
  }

  // ─── ASK QUESTION ─────────────────────────────────────────────────
  Future<String> askQuestion(String slideText, String question) async {
    try {
      if (slideText.trim().isEmpty) {
        return "Error: This lecture document has no readable text.";
      }
      final count = await getTodayCount();
      if (count >= dailyLimit) {
        return "LIMIT_REACHED: You have used all $dailyLimit questions for today. Come back tomorrow!";
      }

      final prompt = """
Answer the student's question based ONLY on the provided lecture slide text.
If the answer is not in the slides, say: "This topic is not covered in these slides."

Lecture Slides Content:
$slideText

Student Question:
$question

Give a thorough, well-explained answer (at least 3-5 sentences). Use examples where relevant.
At the end add the source like this: [Source: Page X]
""";

      final result = await _callAPI(prompt);
      if (!result.startsWith("API Error")) {
        await incrementCount();
      }
      return result;
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  // ─── GENERATE FLASHCARDS ──────────────────────────────────────────
  Future<String> generateFlashcards(String slideText) async {
    if (slideText.trim().isEmpty) return '[]';

    final prompt = """
From these lecture slides generate exactly 10 flashcards.
Return ONLY a valid JSON array. No markdown, no extra text.

[
  {"question": "What is X?", "answer": "X is..."}
]

Lecture Content:
$slideText
""";

    try {
      final raw = await _callAPI(prompt);
      String clean = raw.trim();
      if (clean.contains('```')) clean = clean.replaceAll(RegExp(r'```json|```'), '').trim();
      return clean;
    } catch (e) {
      return '[]';
    }
  }

  // ─── PREDICT EXAM TOPICS ──────────────────────────────────────────
  Future<String> predictExamTopics(String slideText) async {
    if (slideText.trim().isEmpty) return '[]';

    final prompt = """
Analyze the following lecture slide text. Rank topics by exam importance.
Return ONLY a valid JSON array. No markdown, no extra text.

[
  {"topic": "Topic Name", "percentage": 95, "reason": "..."}
]

Lecture Content:
$slideText
""";

    try {
      final raw = await _callAPI(prompt);
      String clean = raw.trim();
      if (clean.contains('```')) clean = clean.replaceAll(RegExp(r'```json|```'), '').trim();
      return clean;
    } catch (e) {
      return '[]';
    }
  }

  // ─── GENERATE MIND MAP ────────────────────────────────────────────
  Future<String> generateMindMap(String slideText) async {
    if (slideText.trim().isEmpty) return '[]';

    final prompt = """
Group these lecture slides into main topic clusters for a mind map.
Return ONLY a valid JSON array. No markdown, no extra text.

[
  {"topic": "Topic Name", "slideRange": "1-10", "color": "purple"}
]

Valid colors: purple, teal, orange, blue, red, green.

Lecture Content:
$slideText
""";

    try {
      final raw = await _callAPI(prompt);
      String clean = raw.trim();
      if (clean.contains('```')) clean = clean.replaceAll(RegExp(r'```json|```'), '').trim();
      return clean;
    } catch (e) {
      return '[]';
    }
  }

  // ─── SMART SUMMARIZE ──────────────────────────────────────────────
  Future<String> _summarizeLargeText(String text) async {
    final words = text.split(' ');
    const chunkSize = 3000;
    final chunks = <String>[];

    for (int i = 0; i < words.length; i += chunkSize) {
      final end = (i + chunkSize < words.length) ? i + chunkSize : words.length;
      chunks.add(words.sublist(i, end).join(' '));
    }

    debugPrint('Summarizing ${chunks.length} chunks...');

    final summaries = <String>[];
    for (int i = 0; i < chunks.length; i++) {
      final prompt = """
Summarize the key concepts, definitions, and important points from this lecture content.
Keep the summary detailed enough to generate exam questions from.
Write at least 300 words covering all major topics.

Lecture chunk ${i + 1} of ${chunks.length}:
${chunks[i]}
""";
      final summary = await _callAPI(prompt, maxTokens: 600);
      if (!summary.startsWith('API Error')) {
        summaries.add('=== Lecture Section ${i + 1} ===\n$summary');
      }
    }

    return summaries.join('\n\n');
  }

  // ─── EXAM SIM — GENERATE PAPER ────────────────────────────────────
  Future<Map<String, dynamic>> generateExamPaper(
    String slideText,
    String format, {
    int mcqCount = 10,
    int shortCount = 5,
    int longCount = 2,
    int shortMarks = 5,
    int longMarks = 10,
  }) async {
    String contentToUse = slideText;
    final wordCount = slideText.split(' ').length;

    if (wordCount > 15000) {
      debugPrint('Content too large ($wordCount words) — summarizing first...');
      contentToUse = await _summarizeLargeText(slideText);
      debugPrint('Summarization complete.');
    }

    final prompt = """
You are an experienced university professor. Generate a complete exam paper from the lecture content below.

Format: $format
Return ONLY valid JSON. No markdown, no extra text.

{
  "mcqs": [
    {
      "question": "Question text here?",
      "options": ["A) option1", "B) option2", "C) option3", "D) option4"],
      "correct": "A"
    }
  ],
  "short_questions": [
    {
      "question": "Short question here?",
      "marks": $shortMarks,
      "model_answer": "Expected answer here"
    }
  ],
  "long_questions": [
    {
      "question": "Long question here?",
      "marks": $longMarks,
      "model_answer": "Detailed expected answer here"
    }
  ]
}

Generate exactly:
- $mcqCount MCQs (4 options each, one correct)
- $shortCount short questions ($shortMarks marks each)
- $longCount long questions ($longMarks marks each)

Make questions from ALL topics. Cover a wide range.

Lecture Content:
$contentToUse
""";

    try {
      final raw = await _callAPI(prompt, maxTokens: 4000);
      String clean = raw.trim();
      if (clean.contains('```')) clean = clean.replaceAll(RegExp(r'```json|```'), '').trim();
      final parsed = jsonDecode(clean);
      return parsed as Map<String, dynamic>;
    } catch (e) {
      return {
        'mcqs': [],
        'short_questions': [],
        'long_questions': [],
        'error': e.toString(),
      };
    }
  }

  // ─── EXAM SIM — GRADE ANSWERS ─────────────────────────────────────
  Future<Map<String, dynamic>> gradeExamAnswers({
    required String slideText,
    required List<Map<String, dynamic>> mcqs,
    required List<String> mcqAnswers,
    required List<Map<String, dynamic>> shortQuestions,
    required List<String> shortAnswers,
    required List<Map<String, dynamic>> longQuestions,
    required List<String> longAnswers,
  }) async {
    int mcqScore = 0;
    List<Map<String, dynamic>> mcqResults = [];
    for (int i = 0; i < mcqs.length; i++) {
      final correct = mcqs[i]['correct']?.toString() ?? '';
      final userAnswer = i < mcqAnswers.length ? mcqAnswers[i] : '';
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

    String gradingContent = slideText;
    if (slideText.split(' ').length > 15000) {
      gradingContent = await _summarizeLargeText(slideText);
    }

    final gradingPrompt = """
You are a strict university professor grading an exam.
Return ONLY valid JSON. No markdown, no extra text.

IMPORTANT GRADING RULES:
- If a student's answer is empty, blank, or says NO ANSWER PROVIDED → award 0 marks, no exceptions
- If a student's answer is partially correct → award partial marks only
- If a student's answer is completely correct → award full marks
- Never give marks for empty or missing answers under any circumstances

{
  "short_results": [
    {
      "question": "question text",
      "user_answer": "student answer",
      "marks_awarded": 0,
      "max_marks": 5,
      "feedback": "No answer provided"
    }
  ],
  "long_results": [
    {
      "question": "question text",
      "user_answer": "student answer",
      "marks_awarded": 0,
      "max_marks": 10,
      "feedback": "No answer provided"
    }
  ],
  "overall_feedback": "Overall performance summary"
}
Lecture Content (answer key):
$gradingContent

Short Questions:
${List.generate(shortQuestions.length, (i) => "Q${i + 1}: ${shortQuestions[i]['question']}\nAnswer: ${i < shortAnswers.length && shortAnswers[i].trim().isNotEmpty ? shortAnswers[i] : 'NO ANSWER PROVIDED - AWARD 0 MARKS'}\nMax: ${shortQuestions[i]['marks']} marks").join('\n\n')}

Long Questions:
${List.generate(longQuestions.length, (i) => "Q${i + 1}: ${longQuestions[i]['question']}\nAnswer: ${i < longAnswers.length && longAnswers[i].trim().isNotEmpty ? longAnswers[i] : 'NO ANSWER PROVIDED - AWARD 0 MARKS'}\nMax: ${longQuestions[i]['marks']} marks").join('\n\n')}
""";

    try {
      final raw = await _callAPI(gradingPrompt, maxTokens: 2000);
      String clean = raw.trim();
      if (clean.contains('```')) clean = clean.replaceAll(RegExp(r'```json|```'), '').trim();
      final gradingResult = jsonDecode(clean) as Map<String, dynamic>;

      int shortScore = 0, shortMax = 0, longScore = 0, longMax = 0;
      for (var r in (gradingResult['short_results'] as List? ?? [])) {
        shortScore += (r['marks_awarded'] as num).toInt();
        shortMax += (r['max_marks'] as num).toInt();
      }
      for (var r in (gradingResult['long_results'] as List? ?? [])) {
        longScore += (r['marks_awarded'] as num).toInt();
        longMax += (r['max_marks'] as num).toInt();
      }

      final totalScore = mcqScore + shortScore + longScore;
      final totalMax = mcqs.length + shortMax + longMax;
      final percentage = totalMax > 0 ? (totalScore / totalMax * 100).round() : 0;

      return {
        'mcq_results': mcqResults,
        'mcq_score': mcqScore,
        'mcq_max': mcqs.length,
        'short_results': gradingResult['short_results'] ?? [],
        'short_score': shortScore,
        'short_max': shortMax,
        'long_results': gradingResult['long_results'] ?? [],
        'long_score': longScore,
        'long_max': longMax,
        'total_score': totalScore,
        'total_max': totalMax,
        'percentage': percentage,
        'overall_feedback': gradingResult['overall_feedback'] ?? '',
        'grade': _getGrade(percentage),
      };
    } catch (e) {
      return {
        'mcq_results': mcqResults,
        'mcq_score': mcqScore,
        'mcq_max': mcqs.length,
        'short_results': [],
        'short_score': 0,
        'short_max': shortQuestions.length * 5,
        'long_results': [],
        'long_score': 0,
        'long_max': longQuestions.length * 10,
        'total_score': mcqScore,
        'total_max': mcqs.length + (shortQuestions.length * 5) + (longQuestions.length * 10),
        'percentage': 0,
        'overall_feedback': 'Grading error: ${e.toString()}',
        'grade': 'F',
      };
    }
  }

  String _getGrade(int percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }
}