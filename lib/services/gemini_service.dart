import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static const int dailyLimit = 50;
  static int _currentKeyIndex = 0;

  List<String> _loadKeys() {
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

  Future<String> _callGroqAPI(String prompt, {int maxTokens = 1024}) async {
    final keys = _loadKeys();
    if (keys.isEmpty) return "API Error: No API keys found in .env";

    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final body = jsonEncode({
      "model": "llama-3.1-8b-instant",
      "messages": [
        {"role": "user", "content": prompt}
      ],
      "temperature": 0.7,
      "max_tokens": maxTokens,
    });

    String lastError = "API Error: Unknown failure";

    for (int attempt = 0; attempt < keys.length; attempt++) {
      final keyIndex = (_currentKeyIndex + attempt) % keys.length;
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
          _currentKeyIndex = keyIndex;
          final data = jsonDecode(response.body);
          return data['choices']?[0]?['message']?['content'] ?? "No answer generated.";
        }

        if (response.statusCode == 429) {
          lastError = "QUOTA_ERROR: Rate limit reached.";
          debugPrint('Groq key #${keyIndex + 1} rate-limited, trying next...');
          continue;
        }

        if (response.statusCode == 401) {
          lastError = "API Error: Invalid API Key (key #${keyIndex + 1})";
          debugPrint('Groq key #${keyIndex + 1} invalid, trying next...');
          continue;
        }

        final error = jsonDecode(response.body);
        return "API Error: ${error['error']?['message'] ?? response.statusCode}";
      } catch (e) {
        lastError = "API Error: ${e.toString()}";
        continue;
      }
    }

    return lastError;
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

      final result = await _callGroqAPI(prompt);
      if (!result.startsWith("QUOTA_ERROR") && !result.startsWith("API Error")) {
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
      final raw = await _callGroqAPI(prompt);
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
      final raw = await _callGroqAPI(prompt);
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
      final raw = await _callGroqAPI(prompt);
      String clean = raw.trim();
      if (clean.contains('```')) clean = clean.replaceAll(RegExp(r'```json|```'), '').trim();
      return clean;
    } catch (e) {
      return '[]';
    }
  }

  // ─── SMART SUMMARIZE — for large multi-lecture content ─────────────
  // Splits text into chunks, summarizes each, returns combined summary
  Future<String> _summarizeLargeText(String text) async {
    // Split into chunks of max 3000 words each
    final words = text.split(' ');
    const chunkSize = 3000;
    final chunks = <String>[];

    for (int i = 0; i < words.length; i += chunkSize) {
      final end = (i + chunkSize < words.length) ? i + chunkSize : words.length;
      chunks.add(words.sublist(i, end).join(' '));
    }

    debugPrint('Summarizing ${chunks.length} chunks for exam generation...');

    // Summarize each chunk
    final summaries = <String>[];
    for (int i = 0; i < chunks.length; i++) {
      final prompt = """
Summarize the key concepts, definitions, and important points from this lecture content.
Keep the summary detailed enough to generate exam questions from.
Write at least 300 words covering all major topics.

Lecture chunk ${i + 1} of ${chunks.length}:
${chunks[i]}
""";
      final summary = await _callGroqAPI(prompt, maxTokens: 600);
      if (!summary.startsWith('API Error') && !summary.startsWith('QUOTA_ERROR')) {
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

    // SMART HANDLING — if text is too large (20+ lectures), summarize first
    String contentToUse = slideText;
    final wordCount = slideText.split(' ').length;

    if (wordCount > 15000) {
      // Too large — summarize each section first then generate from summaries
      debugPrint('Content too large ($wordCount words) — summarizing first...');
      contentToUse = await _summarizeLargeText(slideText);
      debugPrint('Summarization complete. Generating exam from summary...');
    }

    final prompt = """
You are an experienced university professor. Generate a complete exam paper from the lecture content below.

Format: $format
Return ONLY valid JSON. No markdown, no extra text.

JSON format:
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

Make questions from ALL topics covered in the content — not just the first lecture.
Cover a wide range of topics to test comprehensive understanding.

Lecture Content:
$contentToUse
""";

    try {
      final raw = await _callGroqAPI(prompt, maxTokens: 4000);
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
    // Grade MCQs automatically — no AI needed
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

    // For grading use summarized content if too large
    String gradingContent = slideText;
    if (slideText.split(' ').length > 15000) {
      gradingContent = await _summarizeLargeText(slideText);
    }

    final gradingPrompt = """
You are a university professor grading an exam.
Return ONLY valid JSON. No markdown, no extra text.

{
  "short_results": [
    {
      "question": "question text",
      "user_answer": "student answer",
      "marks_awarded": 4,
      "max_marks": 5,
      "feedback": "Good answer but missed X point"
    }
  ],
  "long_results": [
    {
      "question": "question text",
      "user_answer": "student answer",
      "marks_awarded": 8,
      "max_marks": 10,
      "feedback": "Well explained but could improve on Y"
    }
  ],
  "overall_feedback": "Overall performance summary"
}

Lecture Content (answer key):
$gradingContent

Short Questions:
${List.generate(shortQuestions.length, (i) => "Q${i + 1}: ${shortQuestions[i]['question']}\nAnswer: ${i < shortAnswers.length ? shortAnswers[i] : 'No answer'}\nMax: ${shortQuestions[i]['marks']} marks").join('\n\n')}

Long Questions:
${List.generate(longQuestions.length, (i) => "Q${i + 1}: ${longQuestions[i]['question']}\nAnswer: ${i < longAnswers.length ? longAnswers[i] : 'No answer'}\nMax: ${longQuestions[i]['marks']} marks").join('\n\n')}
""";

    try {
      final raw = await _callGroqAPI(gradingPrompt, maxTokens: 2000);
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