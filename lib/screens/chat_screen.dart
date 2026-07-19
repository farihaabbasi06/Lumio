import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme/app_colors.dart';

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

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _currentLocaleId = 'en_US';

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
          pauseFor: const Duration(seconds: 3),
        );
      }
    } else {
      await _speech.stop();
      setState(() => _isListening = false);
    }
  }

  String _buildConversationPrompt(String slideText, String currentQuery) {
    StringBuffer promptBuffer = StringBuffer();
    promptBuffer.writeln(
        "You are an advanced AI study assistant. Here is the reference text context from the student's study slide document:\n=== CONTEXT START ===\n$slideText\n=== CONTEXT END ===\n");
    promptBuffer.writeln(
        "Using both the reference material above and our active conversation history, answer the user's latest message accurately.");

    final historySnapshot = _messages.where((m) => !m['isTyping']).toList();
    final structuralLookback = historySnapshot.length > 6
        ? historySnapshot.sublist(historySnapshot.length - 6)
        : historySnapshot;

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
      _messages.add({'sender': 'user', 'text': userQuery, 'isTyping': false});
      _chatController.clear();
      _isAiTyping = true;
      _messages.add({'sender': 'ai', 'text': '', 'isTyping': true});
    });
    _scrollToBottom();

    try {
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

  Widget _renderFormattedText(String text, TextStyle baseStyle, Color boldColor) {
    List<TextSpan> spans = [];
    final regExp = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    for (final match in regExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start), style: baseStyle));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.bold, color: boldColor),
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

    // Pull the active palette (light or dark) from the current theme.
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          lectureTitle,
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textSecondary),
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
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 44, color: colors.primary.withAlpha(120)),
                        const SizedBox(height: 12),
                        Text(
                          "Ask anything about this document...",
                          style: TextStyle(color: colors.textSecondary, fontSize: 13),
                        ),
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
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                            child: Text(msg['text'],
                                style: TextStyle(color: colors.textPurple, fontSize: 14)),
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
                                  decoration: BoxDecoration(
                                    color: colors.card,
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(15),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: msg['isTyping']
                                      ? SizedBox(
                                          width: 40,
                                          height: 20,
                                          child: Center(child: TypingIndicator(dotColor: colors.textSecondary)),
                                        )
                                      : _renderFormattedText(
                                          msg['text'],
                                          TextStyle(color: colors.textPrimary, fontSize: 14, height: 1.4),
                                          colors.textPrimary,
                                        ),
                                ),
                                if (!msg['isTyping'] && msg['slideNumber'] != null) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colors.accentBg,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: colors.accentBorder, width: 0.5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.bookmark_outline_rounded, color: colors.accent, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Slide ${msg['slideNumber']}',
                                          style: TextStyle(
                                              color: colors.accent, fontSize: 11, fontWeight: FontWeight.bold),
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
            color: colors.background,
            child: SafeArea(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleLanguage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.inputFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.inputBorder, width: 0.5),
                      ),
                      child: Text(
                        _currentLocaleId == 'en_US' ? 'EN' : 'UR',
                        style: TextStyle(color: colors.textPurple == Colors.white ? colors.primary : colors.textPurple, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening ? colors.danger : colors.textSecondary,
                    ),
                    onPressed: () => _toggleListening(slideText),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.inputFill,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _chatController,
                        style: TextStyle(color: colors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ask a question...',
                          hintStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                      backgroundColor: colors.primary,
                      child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
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
  final Color dotColor;
  const TypingIndicator({super.key, this.dotColor = Colors.white70});

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
            decoration: BoxDecoration(
              color: widget.dotColor,
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