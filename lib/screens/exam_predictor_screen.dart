import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_widgets.dart';
import '../theme/app_colors.dart';

class ExamPredictorScreen extends StatelessWidget {
  const ExamPredictorScreen({super.key});

  Color _getImportanceColor(int percentage, AppColors colors) {
    if (percentage >= 80) return colors.danger;
    if (percentage >= 50) return colors.warning;
    return colors.accent;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'Exam AI Predictor',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lectures')
            .where('userId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LumioLoader(message: 'Loading predictions...');
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No data analyzed yet.\nUpload your lecture slides first!',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
            );
          }

          List<Map<String, dynamic>> allPredictedTopics = [];

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['examTopics'] != null && data['examTopics'] is List) {
              final String lectureTitle = data['title'] ?? 'Lecture';
              for (var topicData in data['examTopics']) {
                if (topicData is Map<String, dynamic>) {
                  allPredictedTopics.add({
                    'topic': topicData['topic'] ?? 'Unknown Topic',
                    'percentage': topicData['percentage'] ?? 0,
                    'reason': topicData['reason'] ?? 'No explanation provided.',
                    'lectureTitle': lectureTitle,
                  });
                }
              }
            }
          }

          allPredictedTopics.sort((a, b) => (b['percentage'] as int).compareTo(a['percentage'] as int));

          if (allPredictedTopics.isEmpty) {
            return const LumioEmptyState(
              icon: Icons.track_changes_rounded,
              title: 'No predictions yet',
              subtitle: 'Upload a lecture to see exam topic predictions',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allPredictedTopics.length,
            itemBuilder: (context, index) {
              final item = allPredictedTopics[index];
              final String topicName = item['topic'];
              final int percentage = item['percentage'];
              final String reason = item['reason'];
              final String sourceLecture = item['lectureTitle'];
              final Color statusColor = _getImportanceColor(percentage, colors);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topicName,
                                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Source: $sourceLecture',
                                style: TextStyle(color: colors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$percentage%',
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100.0,
                        backgroundColor: colors.inputFill,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      reason,
                      style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}