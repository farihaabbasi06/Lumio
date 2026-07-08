import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
 
class LectureDetailScreen extends StatefulWidget {
  const LectureDetailScreen({super.key});
 
  @override
  State<LectureDetailScreen> createState() => _LectureDetailScreenState();
}
 
class _LectureDetailScreenState extends State<LectureDetailScreen> {
  final List<Map<String, String?>> _messages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  bool _isLoading = false;
  int _questionsLeft = 20; // shown in UI
 
  static const backgroundColor = Color(0xFF0D0D18);
  static const cardColor = Color(0xFF1A1A2E);
  static const primaryPurple = Color(0xFF534AB7);
  static const accentNeon = Color(0xFF5DCAA5);
  static const textPurple = Color(0xFFCECBF6);
 
  @override
  void initState() {
    super.initState();
   // _resetCounterForTesting();
    // FIX 2: load how many questions are left today when screen opens
    _loadQuestionsLeft();
  }

  Future<void> _resetCounterForTesting() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('question_count', 0);
  await prefs.setString('question_date', '');
}
 
  Future<void> _loadQuestionsLeft() async {
    final remaining = await _geminiService.questionsRemaining();
    if (mounted) {
      setState(() => _questionsLeft = remaining);
    }
  }
 
  void _sendMessage(String extractedText) async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _isLoading) return;
 
    // FIX 2: block send if limit reached before even calling API
    if (_questionsLeft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily question limit reached. Come back tomorrow!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
 
    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _chatController.clear();
      _isLoading = true;
    });
 
    _scrollToBottom();
 
    final aiAnswerString = await _geminiService.askQuestion(extractedText, text);
 
    // FIX 1: handle quota error message from service cleanly
    if (aiAnswerString.startsWith('QUOTA_ERROR') ||
        aiAnswerString.startsWith('LIMIT_REACHED')) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'sender': 'ai',
          'text': aiAnswerString.contains('LIMIT_REACHED')
              ? 'You have used all your questions for today. Come back tomorrow!'
              : 'API daily limit reached. Please try again tomorrow.',
          'slide': null,
        });
        _isLoading = false;
        _questionsLeft = 0;
      });
      _scrollToBottom();
      return;
    }
 
    // Parse slide number from response
    String detectedPage = "1";
    final match = RegExp(
      r'\[Source:\s*(?:Page|Slide)\s*(\d+)\]',
      caseSensitive: false,
    ).firstMatch(aiAnswerString);
    if (match != null) {
      detectedPage = match.group(1)!;
    }
 
    final displayText = aiAnswerString
        .replaceAll(
          RegExp(r'\[Source:\s*(?:Page|Slide)\s*\d+\]', caseSensitive: false),
          '',
        )
        .trim();
 
    if (!mounted) return;
 
    // FIX 2: refresh questions left count after successful answer
    final remaining = await _geminiService.questionsRemaining();
 
    setState(() {
      _messages.add({
        'sender': 'ai',
        'text': displayText,
        'slide': detectedPage,
      });
      _isLoading = false;
      _questionsLeft = remaining;
    });
 
    _scrollToBottom();
  }
 
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }
 
  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String lectureTitle = args['lectureTitle'] ?? 'Lecture Detail';
    final String slideText = args['slideText'] ?? '';
 
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
          lectureTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        // FIX 2: show questions remaining counter in top right
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _questionsLeft > 5
                      ? const Color(0xFF112210)
                      : const Color(0xFF2A1510),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: _questionsLeft > 5
                        ? const Color(0xFF1D9E75)
                        : Colors.redAccent,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '$_questionsLeft left today',
                  style: TextStyle(
                    color: _questionsLeft > 5
                        ? accentNeon
                        : Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 48,
                          color: primaryPurple.withAlpha(150),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Ask Lumio AI anything about this document',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$_questionsLeft questions available today',
                          style: const TextStyle(
                            color: accentNeon,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['sender'] == 'user';
 
                      if (isUser) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16, left: 40),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: const BoxDecoration(
                              color: primaryPurple,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                            child: Text(
                              msg['text']!,
                              style: const TextStyle(
                                color: textPurple,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin:
                                const EdgeInsets.only(bottom: 16, right: 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lumio AI',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    msg['text']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (msg['slide'] != null) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF162525),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFF1D453B),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.description_outlined,
                                          color: accentNeon,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Page ${msg['slide']}',
                                          style: const TextStyle(
                                            color: accentNeon,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
          ),
 
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryPurple,
                  ),
                ),
              ),
            ),
 
          Container(
            padding: const EdgeInsets.all(16),
            color: backgroundColor,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2E),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _chatController,
                        // FIX 2: disable input when limit is 0
                        enabled: !_isLoading && _questionsLeft > 0,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: _questionsLeft > 0
                              ? 'Ask a question...'
                              : 'Daily limit reached — come back tomorrow',
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(slideText),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _sendMessage(slideText),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          (_isLoading || _questionsLeft <= 0)
                              ? Colors.grey
                              : primaryPurple,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.send_rounded, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 