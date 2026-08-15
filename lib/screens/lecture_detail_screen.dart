import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';


class LectureDetailScreen extends StatefulWidget {
  const LectureDetailScreen({super.key});

  @override
  State<LectureDetailScreen> createState() => _LectureDetailScreenState();
}

class _LectureDetailScreenState extends State<LectureDetailScreen> {
  List<Map<String, dynamic>> _weakSpots = [];
  bool _loadingWeakSpots = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String lectureId = args['lectureId'] ?? '';
    final String subjectId = args['subjectId'] ?? '';
    _loadWeakSpots(lectureId);
    _updateSubjectProgress(subjectId, lectureId);
  }

  Future<void> _loadWeakSpots(String lectureId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      final snap = await FirebaseFirestore.instance
          .collection('weakspots')
          .where('userId', isEqualTo: uid)
          .where('lectureId', isEqualTo: lectureId)
          .get();

      final Map<String, int> topicCount = {};
      for (var doc in snap.docs) {
        final topic = doc['topic']?.toString() ?? 'Unknown';
        topicCount[topic] = (topicCount[topic] ?? 0) + 1;
      }

      final sorted = topicCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

      final top3 = sorted.take(3).map((e) => {'topic': e.key, 'count': e.value}).toList();

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

  Future<void> _updateSubjectProgress(String subjectId, String lectureId) async {
    if (subjectId.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('lectures').doc(lectureId).update({'opened': true});

      final allLectures = await FirebaseFirestore.instance
          .collection('lectures')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      final openedLectures = allLectures.docs.where((doc) => doc.data()['opened'] == true).length;

      final total = allLectures.docs.length;
      final progress = total > 0 ? (openedLectures / total) : 0.0;

      await FirebaseFirestore.instance.collection('subjects').doc(subjectId).update({'progress': progress});
    } catch (e) {
      // Silent fail — progress update is not critical
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String lectureTitle = args['lectureTitle'] ?? 'Lecture';
    final String lectureId = args['lectureId'] ?? '';
    final String subjectId = args['subjectId'] ?? '';
    final String slideText = args['slideText'] ?? '';

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
          lectureTitle,
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STUDY TOOLS',
              style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
                _buildToolButton(
                  colors: colors,
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'AI Chat',
                  subtitle: 'Ask anything',
                  color: colors.primary,
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
                _buildToolButton(
                  colors: colors,
                  icon: Icons.style_rounded,
                  label: 'Flashcards',
                  subtitle: 'Test yourself',
                  color: colors.warning,
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
                _buildToolButton(
                  colors: colors,
                  icon: Icons.track_changes_rounded,
                  label: 'Exam AI',
                  subtitle: 'Predict topics',
                  color: colors.accent,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/exam-predictor',
                    arguments: {
                      'lectureId': lectureId,
                      'lectureTitle': lectureTitle,
                    },
                  ),
                ),




                





                _buildToolButton(
                  colors: colors,
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

            Text(
              'FOCUS ON THESE',
              style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),

            if (_loadingWeakSpots)
              Center(child: CircularProgressIndicator(color: colors.primary, strokeWidth: 2))
            else if (_weakSpots.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: colors.accent, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'No weak spots yet — keep studying!',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
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
                      color: colors.danger.withAlpha(20),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.danger.withAlpha(80), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: colors.danger, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                spot['topic'],
                                style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Got wrong ${spot['count']} times',
                                style: TextStyle(color: colors.danger, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
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
                              color: colors.danger.withAlpha(35),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colors.danger.withAlpha(100)),
                            ),
                            child: Text('Study', style: TextStyle(color: colors.danger, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 28),

            Text(
              'LECTURE INFO',
              style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.description_outlined, color: colors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lectureTitle,
                          style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          slideText.isEmpty ? 'No text extracted' : '${slideText.split(' ').length} words extracted',
                          style: TextStyle(color: colors.textSecondary, fontSize: 11),
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
    required AppColors colors,
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
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(80), width: 0.5),
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
                Text(subtitle, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}