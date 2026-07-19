import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'dart:math';
import '../widgets/app_widgets.dart';
import '../theme/app_colors.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _cards = [];
  int _currentIndex = 0;
  bool _showFront = true;
  bool _isLoading = true;

  int _correctCount = 0;

  late AnimationController _animationController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _flipAnimation = Tween<double>(begin: 0.0, end: pi).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cards.isEmpty) {
      _loadFlashcards();
    }
  }

  Future<void> _loadFlashcards() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String lectureId = args['lectureId'] ?? '';

    try {
      var box = await Hive.openBox('flashcards');
      String? cachedJson = box.get(lectureId);

      if (cachedJson != null) {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        setState(() {
          _cards = decoded.map((c) => Map<String, dynamic>.from(c)).toList();
          _isLoading = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('flashcards')
          .where('lectureId', isEqualTo: lectureId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final cloudCards = snapshot.docs.map((doc) => {
          'question': doc['question'].toString(),
          'answer': doc['answer'].toString(),
          'topic': doc.data().containsKey('topic') ? doc['topic'].toString() : 'General Concept',
        }).toList();

        await box.put(lectureId, jsonEncode(cloudCards));

        setState(() {
          _cards = cloudCards;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      print("Error loading flashcards: $e");
    }

    setState(() => _isLoading = false);
  }

  void _toggleFlip() {
    if (_showFront) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    setState(() => _showFront = !_showFront);
  }

  void _gradeCard(bool knewAnswer, String lectureId, String subjectId, AppColors colors) async {
    if (knewAnswer) {
      _correctCount++;
    } else {
      final String cardTopic = _cards[_currentIndex]['topic'] ?? _cards[_currentIndex]['question']!.split('?').first;
      final String? userId = FirebaseAuth.instance.currentUser?.uid;

      FirebaseFirestore.instance.collection('weakspots').add({
        'topic': cardTopic,
        'lectureId': lectureId,
        'userId': userId ?? 'anonymous_user',
        'timestamp': FieldValue.serverTimestamp(),
        'subjectId': subjectId,
      });
    }

    if (_currentIndex < _cards.length - 1) {
      _nextCard();
    } else {
      _showCompletionDialog(colors);
    }
  }

  void _nextCard() {
    if (_currentIndex < _cards.length - 1) {
      if (!_showFront) _toggleFlip();
      Future.delayed(const Duration(milliseconds: 150), () {
        setState(() => _currentIndex++);
      });
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      if (!_showFront) _toggleFlip();
      Future.delayed(const Duration(milliseconds: 150), () {
        setState(() => _currentIndex--);
      });
    }
  }

  void _showCompletionDialog(AppColors colors) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Deck Complete! 🎉', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Great session! You mastered $_correctCount out of ${_cards.length} cards properly.',
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Back to Dashboard', style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String lectureTitle = args['lectureTitle'] ?? 'Flashcards';
    final String lectureId = args['lectureId'] ?? '';
    final String subjectId = args['subjectId'] ?? '';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '$lectureTitle Deck',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: _isLoading
          ? LumioLoader(message: 'Loading flashcards...')
          : _cards.isEmpty
              ? const LumioEmptyState(
                  icon: Icons.style_rounded,
                  title: 'No flashcards yet',
                  subtitle: 'Upload a lecture PDF to auto-generate flashcards',
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: (_currentIndex + 1) / _cards.length,
                        backgroundColor: colors.inputFill,
                        color: colors.accent,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Card ${_currentIndex + 1} of ${_cards.length}',
                            style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Spacer(),

                      GestureDetector(
                        onTap: _toggleFlip,
                        child: AnimatedBuilder(
                          animation: _flipAnimation,
                          builder: (context, child) {
                            final angle = _flipAnimation.value;
                            final isBackView = angle >= (pi / 2);

                            return Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(angle),
                              alignment: Alignment.center,
                              child: Transform(
                                transform: isBackView
                                    ? (Matrix4.identity()..rotateY(pi))
                                    : Matrix4.identity(),
                                alignment: Alignment.center,
                                child: Container(
                                  width: double.infinity,
                                  height: MediaQuery.of(context).size.height * 0.42,
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: colors.card,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isBackView ? colors.accent.withAlpha(100) : colors.primary.withAlpha(100),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(70),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      )
                                    ],
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isBackView ? Icons.check_circle_outline_rounded : Icons.help_outline_rounded,
                                          color: isBackView ? colors.accent : colors.primary,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          isBackView ? 'ANSWER' : 'QUESTION',
                                          style: TextStyle(
                                            color: isBackView ? colors.accent : colors.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          isBackView
                                              ? _cards[_currentIndex]['answer']!
                                              : _cards[_currentIndex]['question']!,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const Spacer(),

                      if (!_showFront) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.danger.withAlpha(25),
                                  foregroundColor: colors.danger,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(color: colors.danger, width: 0.5),
                                  ),
                                ),
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: const Text("Didn't Know", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                onPressed: () => _gradeCard(false, lectureId, subjectId, colors),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.accent.withAlpha(25),
                                  foregroundColor: colors.accent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(color: colors.accent, width: 0.5),
                                  ),
                                ),
                                icon: const Icon(Icons.check_rounded, size: 16),
                                label: const Text("Got It", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                onPressed: () => _gradeCard(true, lectureId, subjectId, colors),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: colors.card,
                              disabledBackgroundColor: colors.surface,
                            ),
                            icon: Icon(Icons.chevron_left_rounded, color: colors.textPrimary),
                            onPressed: _currentIndex > 0 ? _previousCard : null,
                          ),
                          TextButton.icon(
                            onPressed: _toggleFlip,
                            icon: Icon(Icons.flip_rounded, color: colors.textPurple == Colors.white ? colors.primary : colors.textPurple, size: 18),
                            label: Text('Tap Card to Flip', style: TextStyle(color: colors.textPurple == Colors.white ? colors.primary : colors.textPurple, fontSize: 13)),
                          ),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: colors.card,
                              disabledBackgroundColor: colors.surface,
                            ),
                            icon: Icon(Icons.chevron_right_rounded, color: colors.textPrimary),
                            onPressed: _currentIndex < _cards.length - 1 ? _nextCard : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}