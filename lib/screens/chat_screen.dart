import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();

  bool _isAiTyping = false;

  // Speech to Text configuration variables
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  // User-selectable language for speech recognition. Defaults to English.
  String _currentLocaleId = 'en_US';

  // Custom Dark Theme Palette Colors
  static const backgroundColor = Color(0xFF0D0D18);
  static const cardColor = Color(0xFF1A1A2E);
  static const primaryPurple = Color(0xFF534AB7);
  static const accentNeon = Color(0xFF5DCAA5);
  static const textPurple = Color(0xFFCECBF6);

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Lets the user switch between English and Urdu recognition.
  void _toggleLanguage() {
    if (_isListening) return;
    setState(() {
      _currentLocaleId = _currentLocaleId == 'en_US' ? 'ur_PK' : 'en_US';
    });
  }

  void _toggleListening(String slideText) async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            setState(() => _isListening = false);
            final textToSend = _chatController.text.trim();
            if (textToSend.isNotEmpty) {
              _sendMessage(slideText);
            }
          }
        },
        onError: (errorNotification) => setState(() => _isListening = false),
      );

      if (available) {
        setState(() => _isListening = true);

        await _speech.listen(
          onResult: (result) {
            setState(() {
              _chatController.text = result.recognizedWords;
            });
          },
          localeId: _currentLocaleId,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3)
        );
      }
    } else {
      await _speech.stop();
      setState(() => _isListening = false);
    }
  }

  // Helper function to build a consolidated prompt log of past chat history
  String _buildConversationPrompt(String slideText, String currentQuery) {
    StringBuffer promptBuffer = StringBuffer();
    promptBuffer.writeln("You are an advanced AI study assistant. Here is the reference text context from the student's study slide document:\n=== CONTEXT START ===\n$slideText\n=== CONTEXT END ===\n");
    promptBuffer.writeln("Using both the reference material above and our active conversation history, answer the user's latest message accurately.");
    
    // Append the last 6 turns of context to manage token sizes efficiently
    final historySnapshot = _messages.where((m) => !m['isTyping']).toList();
    final structuralLookback = historySnapshot.length > 6 ? historySnapshot.sublist(historySnapshot.length - 6) : historySnapshot;
    
    for (var historicMsg in structuralLookback) {
      final role = historicMsg['sender'] == 'user' ? 'Student' : 'AI Assistant';
      promptBuffer.writeln("$role: ${historicMsg['text']}");
    }
    
    promptBuffer.writeln("Student: $currentQuery");
    promptBuffer.write("AI Assistant: ");
    return promptBuffer.toString();
  }

  void _sendMessage(String slideText) async {
    final userQuery = _chatController.text.trim();
    if (userQuery.isEmpty || _isAiTyping) return;

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': userQuery,
        'isTyping': false,
      });
      _chatController.clear();
      _isAiTyping = true;

      _messages.add({
        'sender': 'ai',
        'text': '',
        'isTyping': true,
      });
    });
    _scrollToBottom();

    try {
      // Build a multi-turn history-aware prompt instead of sending just the immediate query
      final contextAwarePrompt = _buildConversationPrompt(slideText, userQuery);
      final rawAiResponse = await _geminiService.askQuestion(slideText, contextAwarePrompt);

      String? extractedSlideNumber;
      final regExp = RegExp(r'(?:slide|page)\s*(\d+)', caseSensitive: false);
      final match = regExp.firstMatch(rawAiResponse);
      if (match != null) {
        extractedSlideNumber = match.group(1);
      }

      setState(() {
        _messages.removeLast(); 
        _messages.add({
          'sender': 'ai',
          'text': rawAiResponse,
          'isTyping': false,
          'slideNumber': extractedSlideNumber,
        });
        _isAiTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add({
          'sender': 'ai',
          'text': "Sorry, I encountered an issue retrieving the response. Please try again.",
          'isTyping': false,
        });
        _isAiTyping = false;
      });
    }
    _scrollToBottom();
  }

  // Simple runtime parsing layout for processing bold text markers safely without crash dependencies
  Widget _renderFormattedText(String text, TextStyle baseStyle) {
    List<TextSpan> spans = [];
    final regExp = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    for (final match in regExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start), style: baseStyle));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
    }

    return RichText(text: TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String lectureTitle = args['lectureTitle'] ?? 'Document Chat';
    final String slideText = args['slideText'] ?? '';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF131324),
        elevation: 0,
        title: Text(
          lectureTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 44, color: primaryPurple.withAlpha(120)),
                        const SizedBox(height: 12),
                        const Text("Ask anything about this document...", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['sender'] == 'user';

                      if (isUser) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14, left: 50),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              color: primaryPurple,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                            child: Text(msg['text'], style: const TextStyle(color: textPurple, fontSize: 14)),
                          ),
                        );
                      } else {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14, right: 50),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: const BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: msg['isTyping']
                                      ? const SizedBox(width: 40, height: 20, child: Center(child: TypingIndicator()))
                                      : _renderFormattedText(msg['text'], const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                                ),
                                if (!msg['isTyping'] && msg['slideNumber'] != null) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF162525),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF1D453B), width: 0.5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.bookmark_outline_rounded, color: accentNeon, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Slide ${msg['slideNumber']}',
                                          style: const TextStyle(color: accentNeon, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0D0D18),
            child: SafeArea(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleLanguage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF3C3489), width: 0.5),
                      ),
                      child: Text(
                        _currentLocaleId == 'en_US' ? 'EN' : 'UR',
                        style: const TextStyle(
                          color: textPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening ? Colors.redAccent : Colors.grey,
                    ),
                    onPressed: () => _toggleListening(slideText),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2E),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _chatController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Ask a question...',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(slideText),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _sendMessage(slideText),
                    child: const CircleAvatar(
                      radius: 22,
                      backgroundColor: primaryPurple,
                      child: Icon(Icons.send_rounded, size: 18, color: Colors.white),
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

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        double delay = index * 0.2;
        double progress = (_animationController.value - delay) % 1.0;
        double targetValue = (progress < 0.5) ? progress * 2 : (1.0 - progress) * 2;

        return Opacity(
          opacity: 0.3 + (targetValue.clamp(0.0, 1.0) * 0.7),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.white70,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) => _buildDot(index)),
    );
  }
}