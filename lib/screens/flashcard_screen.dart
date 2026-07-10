import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'dart:math';

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
  
  // Performance Tracking States
  int _correctCount = 0;

  late AnimationController _animationController;
  late Animation<double> _flipAnimation;

  static const backgroundColor = Color(0xFF0D0D18);
  static const cardColor = Color(0xFF1A1A2E);
  static const primaryPurple = Color(0xFF534AB7);
  static const accentNeon = Color(0xFF5DCAA5);
  static const textPurple = Color(0xFFCECBF6);

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

  // Handle grading choices and route forward
  void _gradeCard(bool knewAnswer, String lectureId) async {
    if (knewAnswer) {
      _correctCount++;
    } else {
      // Isolate the fallback topic text or parse out question text summary
      final String cardTopic = _cards[_currentIndex]['topic'] ?? _cards[_currentIndex]['question']!.split('?').first;
      final String? userId = FirebaseAuth.instance.currentUser?.uid;

      // Async push up structural weak spot log entry to Firestore
      FirebaseFirestore.instance.collection('weakspots').add({
        'topic': cardTopic,
        'lectureId': lectureId,
        'userId': userId ?? 'anonymous_user',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    // Move to next card or complete deck run
    if (_currentIndex < _cards.length - 1) {
      _nextCard();
    } else {
      _showCompletionDialog();
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

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Deck Complete! 🎉', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Great session! You mastered $_correctCount out of ${_cards.length} cards properly.',
          style: const TextStyle(color: textPurple, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to subject screen
            },
            child: const Text('Back to Dashboard', style: TextStyle(color: accentNeon, fontWeight: FontWeight.bold)),
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
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String lectureTitle = args['lectureTitle'] ?? 'Flashcards';
    final String lectureId = args['lectureId'] ?? '';

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
          '$lectureTitle Deck',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryPurple))
          : _cards.isEmpty
              ? const Center(
                  child: Text(
                    'AI Flashcards are still generating.\nGive it a few moments and try reopening!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: (_currentIndex + 1) / _cards.length,
                        backgroundColor: const Color(0xFF1E1E2E),
                        color: accentNeon,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end, 
                        children: [
                          Text(
                            'Card ${_currentIndex + 1} of ${_cards.length}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Flipping Card Layout View
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
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isBackView ? accentNeon.withAlpha(100) : primaryPurple.withAlpha(100),
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
                                          color: isBackView ? accentNeon : primaryPurple,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          isBackView ? 'ANSWER' : 'QUESTION',
                                          style: TextStyle(
                                            color: isBackView ? accentNeon : primaryPurple,
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
                                          style: const TextStyle(
                                            color: Colors.white,
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

                      // Action Buttons Layout Row (Revealed post flip trigger animation)
                      if (!_showFront) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2A1515),
                                  foregroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: const BorderSide(color: Colors.redAccent, width: 0.5),
                                  ),
                                ),
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: const Text("Didn't Know", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                onPressed: () => _gradeCard(false, lectureId),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF112210),
                                  foregroundColor: accentNeon,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: const BorderSide(color: accentNeon, width: 0.5),
                                  ),
                                ),
                                icon: const Icon(Icons.check_rounded, size: 16),
                                label: const Text("Got It", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                onPressed: () => _gradeCard(true, lectureId),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Navigation Action Row controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: cardColor,
                              disabledBackgroundColor: const Color(0xFF131324),
                            ),
                            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                            onPressed: _currentIndex > 0 ? _previousCard : null,
                          ),
                          TextButton.icon(
                            onPressed: _toggleFlip,
                            icon: const Icon(Icons.flip_rounded, color: textPurple, size: 18),
                            label: const Text('Tap Card to Flip', style: TextStyle(color: textPurple, fontSize: 13)),
                          ),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: cardColor,
                              disabledBackgroundColor: const Color(0xFF131324),
                            ),
                            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
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