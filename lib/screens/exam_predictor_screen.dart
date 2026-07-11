import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExamPredictorScreen extends StatelessWidget {
  const ExamPredictorScreen({super.key});

  // Matching your exact Lumio application color palette
  static const backgroundColor = Color(0xFF0D0D18);
  static const cardColor = Color(0xFF1A1A2E);
  static const primaryPurple = Color(0xFF534AB7);
  static const textPurple = Color(0xFFCECBF6);
  
  static const redDanger = Color(0xFFE24B4A);
  static const orangeWarn = Color(0xFFEF9F27);
  static const accentNeon = Color(0xFF5DCAA5); // Mint color

  // Helper method to dynamically pick indicator colors based on percentage
  Color _getImportanceColor(int percentage) {
    if (percentage >= 80) return redDanger;
    if (percentage >= 50) return orangeWarn;
    return accentNeon;
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF131324),
        elevation: 0,
        title: const Text(
          'Exam AI Predictor',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetches all lectures uploaded across any subjects for this specific logged-in user
        stream: FirebaseFirestore.instance
            .collection('lectures')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryPurple));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No data analyzed yet.\nUpload your lecture slides first!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            );
          }

          // Combine all predicted topics from all lecture documents into a single flat list
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

          // Sort everything globally by highest probability percentage first
          allPredictedTopics.sort((a, b) => (b['percentage'] as int).compareTo(a['percentage'] as int));

          if (allPredictedTopics.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text( // <-- Fixed from print: to child:
                  'Processing predictions...\nIf you just uploaded a file, give the AI a few seconds to update.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
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
              final Color statusColor = _getImportanceColor(percentage);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF22223B), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row for Topic Name and Percentage Text
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
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Source: $sourceLecture',
                                style: const TextStyle(color: textPurple, fontSize: 11),
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
                    
                    // Linear progress gauge bar colored dynamically
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100.0,
                        backgroundColor: const Color(0xFF252542),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // AI breakdown analysis string snippet
                    Text(
                      reason,
                      style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
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