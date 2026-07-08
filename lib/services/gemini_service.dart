import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static const int dailyLimit = 20;

  // Direct HTTP call — safely extracts your key from the .env file variable pool
  Future<String> _callGeminiAPI(String prompt) async {
    // This looks up your .env file key directly
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
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
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      return text ?? "The AI could not generate an answer.";
    } else {
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      final error = jsonDecode(response.body);
      return "API Error: ${error['error']['message']}";
    }
  }

  // Generate structured Flashcards JSON array from text extraction
  Future<String> generateFlashcards(String slideText) async {
    if (slideText.trim().isEmpty) {
      return '[]';
    }

    final prompt = """
From these lecture slides generate exactly 10 flashcards. 
Return ONLY a valid JSON array like the example below. Do not include markdown code block formatting (like ```json or ```), no conversational intros, and no extra text.

Example Format:
[
  {"question": "What is the primary topic of Slide 1?", "answer": "The core concept definition."},
  {"question": "Explain the secondary point outlined in the text.", "answer": "The step-by-step process details."}
]

Lecture Content:
$slideText
""";

    try {
      final rawResponse = await _callGeminiAPI(prompt);
      
      String cleanResponse = rawResponse.trim();
      
      // Clean up code blocks if Gemini ignores the prompt instruction and wraps it anyway
      if (cleanResponse.contains('```')) {
        cleanResponse = cleanResponse
            .replaceAll(RegExp(r'```json|```'), '')
            .trim();
      }
      
      return cleanResponse;
    } catch (e) {
      print("Error generating flashcards: $e");
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

      final result = await _callGeminiAPI(prompt);

      if (!result.startsWith("QUOTA_ERROR") && !result.startsWith("API Error")) {
        await incrementCount();
      }

      return result;
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }
}