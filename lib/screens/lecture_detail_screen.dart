import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LectureDetailScreen extends StatefulWidget {
  const LectureDetailScreen({super.key});

  @override
  State<LectureDetailScreen> createState() => _LectureDetailScreenState();
}

class _LectureDetailScreenState extends State<LectureDetailScreen> {
  List<Map<String, dynamic>> _weakSpots = [];
  bool _loadingWeakSpots = true;

  static const backgroundColor = Color(0xFF0D0D18);
  static const cardColor = Color(0xFF1A1A2E);
  static const primaryPurple = Color(0xFF534AB7);
  static const accentNeon = Color(0xFF5DCAA5);
  static const textPurple = Color(0xFFCECBF6);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String lectureId = args['lectureId'] ?? '';
    final String subjectId = args['subjectId'] ?? '';
    _loadWeakSpots(lectureId);
    _updateSubjectProgress(subjectId, lectureId);
  }

  // Load weak spots for this lecture grouped by topic
  Future<void> _loadWeakSpots(String lectureId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      final snap = await FirebaseFirestore.instance
          .collection('weakspots')
          .where('userId', isEqualTo: uid)
          .where('lectureId', isEqualTo: lectureId)
          .get();

      // Group by topic and count occurrences
      final Map<String, int> topicCount = {};
      for (var doc in snap.docs) {
        final topic = doc['topic']?.toString() ?? 'Unknown';
        topicCount[topic] = (topicCount[topic] ?? 0) + 1;
      }

      // Sort by highest count and take top 3
      final sorted = topicCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final top3 = sorted.take(3).map((e) => {
        'topic': e.key,
        'count': e.value,
      }).toList();

      if (mounted) {
        setState(() {
          _weakSpots = top3;
          _loadingWeakSpots = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingWeakSpots = false);
    }
  }

  // Update subject progress when lecture is opened
  Future<void> _updateSubjectProgress(String subjectId, String lectureId) async {
    if (subjectId.isEmpty) return;
    try {
      // Mark this lecture as opened
      await FirebaseFirestore.instance
          .collection('lectures')
          .doc(lectureId)
          .update({'opened': true});

      // Count total lectures and opened lectures in subject
      final allLectures = await FirebaseFirestore.instance
          .collection('lectures')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      final openedLectures = allLectures.docs
          .where((doc) => doc.data()['opened'] == true)
          .length;

      final total = allLectures.docs.length;
      final progress = total > 0 ? (openedLectures / total * 100).round() : 0;

      // Update progress on subject document
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(subjectId)
          .update({'progress': progress});
    } catch (e) {
      // Silent fail — progress update is not critical
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String lectureTitle = args['lectureTitle'] ?? 'Lecture';
    final String lectureId = args['lectureId'] ?? '';
    final String subjectId = args['subjectId'] ?? '';
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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // SECTION 1 — 4 feature buttons
            const Text(
              'STUDY TOOLS',
              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [

                // Button 1 — Chat
                _buildToolButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'AI Chat',
                  subtitle: 'Ask anything',
                  color: primaryPurple,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/chat',
                    arguments: {
                      'lectureId': lectureId,
                      'lectureTitle': lectureTitle,
                      'subjectId': subjectId,
                      'slideText': slideText,
                    },
                  ),
                ),

                // Button 2 — Flashcards
                _buildToolButton(
                  icon: Icons.style_rounded,
                  label: 'Flashcards',
                  subtitle: 'Test yourself',
                  color: const Color(0xFFEF9F27),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/flashcards',
                    arguments: {
                      'lectureId': lectureId,
                      'lectureTitle': lectureTitle,
                      'subjectId': subjectId,
                    },
                  ),
                ),

                // Button 3 — Exam AI
                _buildToolButton(
                  icon: Icons.track_changes_rounded,
                  label: 'Exam AI',
                  subtitle: 'Predict topics',
                  color: accentNeon,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/exam-predictor',
                    arguments: {
                      'lectureId': lectureId,
                      'lectureTitle': lectureTitle,
                    },
                  ),
                ),

                // Button 4 — Mind Map
                _buildToolButton(
                  icon: Icons.hub_rounded,
                  label: 'Mind Map',
                  subtitle: 'Visual overview',
                  color: const Color(0xFF3A86FF),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/mindmap',
                    arguments: {
                      'lectureId': lectureId,
                      'subjectId': subjectId,
                      'lectureTitle': lectureTitle,
                      'slideText': slideText,
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // SECTION 2 — Weak spot report
            const Text(
              'FOCUS ON THESE',
              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),

            if (_loadingWeakSpots)
              const Center(child: CircularProgressIndicator(color: primaryPurple, strokeWidth: 2))
            else if (_weakSpots.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: accentNeon, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'No weak spots yet — keep studying!',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _weakSpots.map((spot) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1015),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                spot['topic'],
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Got wrong ${spot['count']} times',
                                style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        // Quick chat button for this weak spot
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/chat',
                            arguments: {
                              'lectureId': lectureId,
                              'lectureTitle': lectureTitle,
                              'subjectId': subjectId,
                              'slideText': slideText,
                              'initialMessage': 'Explain ${spot['topic']} in detail',
                            },
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A1520),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                            ),
                            child: const Text('Study', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 28),

            // SECTION 3 — Slide overview info
            const Text(
              'LECTURE INFO',
              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, color: primaryPurple, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lectureTitle,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          slideText.isEmpty ? 'No text extracted' : '${slideText.split(' ').length} words extracted',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 26),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}