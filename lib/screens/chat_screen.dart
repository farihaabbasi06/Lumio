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

  // Custom Dark Theme Palette
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

  void _sendMessage(String slideText) async {
  final userQuery = _chatController.text.trim();
  if (userQuery.isEmpty || _isAiTyping) return;

  // 1. Clear textfield and post User Message immediately
  setState(() {
    _messages.add({
      'sender': 'user',
      'text': userQuery,
      'isTyping': false,
    });
    _chatController.clear();
    _isAiTyping = true;
    final stt.SpeechToText _speech = stt.SpeechToText();
bool _isListening = false;
String _currentLocaleId = 'en_US'; // Default language setting
    
    // 2. Insert a temporary message representing the typing indicator state
    _messages.add({
      'sender': 'ai',
      'text': '',
      'isTyping': true,
    });
  });
  _scrollToBottom();

  try {
    // 3. Dispatch text data payload to your Gemini Service instance
    final rawAiResponse = await _geminiService.askQuestion(slideText, userQuery);

    // 4. Regex Parser: Extract mentions of slide or page numbers (e.g. "slide 4" or "page 12")
    String? extractedSlideNumber;
    final regExp = RegExp(r'(?:slide|page)\s*(\d+)', caseSensitive: false);
    final match = regExp.firstMatch(rawAiResponse);
    if (match != null) {
      extractedSlideNumber = match.group(1);
    }

    // 5. Remove the temporary typing element and insert the authentic AI response payload
    setState(() {
      _messages.removeLast(); // Drops the typing bubble
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

 @override
Widget build(BuildContext context) {
  // Catch passed dynamic bundle string references from navigation parameters
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
        // 1. CHAT MESSAGE LIST STREAM AREA
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
                      // AI Bubble Layout
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
                                    : Text(msg['text'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                              ),
                              // DYNAMIC CHIP CONDITIONAL INJECTION
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

        // 2. BOTTOM CONTROL ROW PANEL INTERFACE
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF0D0D18),
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
        // Create an offset delay for each individual dot's pulse phase
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