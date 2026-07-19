
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_widgets.dart';
import '../theme/app_colors.dart';

class WeakSpotsScreen extends StatelessWidget {
  const WeakSpotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String subjectId = args['subjectId'] ?? '';
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

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
          'Targeted Weak Spots',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('weakspots')
            .where('userId', isEqualTo: userId ?? 'anonymous_user')
            .where('subjectId', isEqualTo: subjectId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colors.danger));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return LumioEmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'No weak spots yet',
              subtitle: 'Study flashcards and weak areas will appear here',
              iconColor: colors.accent,
            );
          }

          final Map<String, int> topicCounts = {};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final String topic = data['topic'] ?? 'General Concept';
            topicCounts[topic] = (topicCounts[topic] ?? 0) + 1;
          }

          final sortedTopics = topicCounts.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: sortedTopics.length,
            itemBuilder: (context, index) {
              final String topicName = sortedTopics[index];
              final int missedCount = topicCounts[topicName]!;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.danger.withAlpha(40), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.danger.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.trending_down_rounded, color: colors.danger, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topicName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Missed $missedCount times in sessions',
                            style: TextStyle(color: colors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
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