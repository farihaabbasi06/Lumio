import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static const int dailyLimit = 50;

  // Groq API call — replaces Gemini completely
  Future<String> _callGroqAPI(String prompt) async {
    final apiKey = dotenv.env['GROK_API_KEY'] ?? '';

    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final body = jsonEncode({
      "model": "llama-3.3-70b-versatile",
      "messages": [
        {"role": "user", "content": prompt}
      ],
      "temperature": 0.7,
      "max_tokens": 1024,
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
      return data['choices']?[0]?['message']?['content'] ?? "No answer generated.";
    } else if (response.statusCode == 429) {
      return "QUOTA_ERROR: Rate limit reached. Please wait a moment and try again.";
    } else {
      final error = jsonDecode(response.body);
      return "API Error: ${error['error']?['message'] ?? response.statusCode}";
    }
  }

  Future<String> generateFlashcards(String slideText) async {
    if (slideText.trim().isEmpty) return '[]';

    final prompt = """
From these lecture slides generate exactly 10 flashcards.
Return ONLY a valid JSON array. No markdown, no extra text.

Example:
[
  {"question": "What is X?", "answer": "X is..."},
  {"question": "Explain Y.", "answer": "Y means..."}
]

Lecture Content:
$slideText
""";

    try {
      final raw = await _callGroqAPI(prompt);
      String clean = raw.trim();
      if (clean.contains('```')) {
        clean = clean.replaceAll(RegExp(r'```json|```'), '').trim();
      }
      return clean;
    } catch (e) {
      return '[]';
    }
  }

  Future<String> predictExamTopics(String slideText) async {
    if (slideText.trim().isEmpty) return '[]';

    final prompt = """
Analyse these lecture slides. Rank topics by exam importance. 
Return ONLY a valid JSON array. No markdown, no extra text.
Ensure it is sorted by percentage from highest to lowest.

Example:
[
  {"topic": "Time Complexity", "percentage": 95, "reason": "Mentioned on multiple slides with core algorithms."},
  {"topic": "Memory Allocation", "percentage": 65, "reason": "Covered briefly in a summary slide."}
]

Lecture Content:
$slideText
""";

    try {
      final raw = await _callGroqAPI(prompt);
      String clean = raw.trim();
      if (clean.contains('```')) {
        clean = clean.replaceAll(RegExp(r'```json|```'), '').trim();
      }
      return clean;
    } catch (e) {
      return '[]';
    }
  }

  Future<String> generateMindMap(String slideText) async {
  if (slideText.trim().isEmpty) return '[]';

  final prompt = """
Analyze the following lecture slide text. Group these lecture slides into main topic clusters suitable for a high-level mind map.

Return ONLY a valid JSON array. No markdown, no extra text.

Expected format:
[
  {"topic": "Topic Name", "slideRange": "1-10", "color": "purple"},
  {"topic": "Another Topic", "slideRange": "11-21", "color": "teal"}
]

Valid colors: "purple", "teal", "orange", "blue", "red", "green".

Lecture Content:
$slideText
""";

  try {
    final raw = await _callGroqAPI(prompt);
    String clean = raw.trim();
    if (clean.contains('```')) {
      clean = clean.replaceAll(RegExp(r'```json|```'), '').trim();
    }
    return clean;
  } catch (e) {
    return '[]';
  }
}
  
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

Give a clear and direct answer. At the end add the source like this: [Source: Page X]
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
}