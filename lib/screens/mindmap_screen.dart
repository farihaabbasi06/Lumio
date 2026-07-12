import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MindMapScreen extends StatelessWidget {
  const MindMapScreen({super.key});

  // App color theme palette matching SubjectScreen
  static const backgroundColor = Color(0xFF0D0D18);
  static const cardColor = Color(0xFF1A1A2E);
  static const primaryPurple = Color(0xFF534AB7);

  // Helper method to resolve JSON color strings to actual Flutter colors
  Color _resolveNodeColor(String? colorStr) {
    switch (colorStr?.toLowerCase()) {
      case 'purple': return const Color(0xFF8B5CF6);
      case 'teal': return const Color(0xFF14B8A6);
      case 'orange': return const Color(0xFFF97316);
      case 'blue': return const Color(0xFF3B82F6);
      case 'red': return const Color(0xFFEF4444);
      case 'green': return const Color(0xFF10B981);
      default: return const Color(0xFF6B7280); // Fallback grey
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract route arguments safely
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String lectureId = args['lectureId'] ?? '';
    final String lectureTitle = args['lectureTitle'] ?? 'Mind Map';
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lectureTitle,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text(
              'AI Topic Clusters',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('lectures').doc(lectureId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryPurple));
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Failed to load mind map. Try uploading again.', style: TextStyle(color: Colors.grey)),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> nodes = data['mindMapNodes'] ?? [];

          if (nodes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hub_outlined, color: Colors.grey, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'No mind map nodes generated yet.\nUpload a new lecture to create a cluster index!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: nodes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemBuilder: (context, index) {
              final node = nodes[index] as Map<String, dynamic>;
              final String topic = node['topic'] ?? 'Unknown Topic';
              final String slideRange = node['slideRange'] ?? 'N/A';
              final Color accentColor = _resolveNodeColor(node['color']);

              return GestureDetector(
                onTap: () {
                  // Direct navigation hook to chat screen with pre-filled content parameter layout
                  Navigator.pushNamed(
                    context,
                    '/chat',
                    arguments: {
                      'lectureId': lectureId,
                      'lectureTitle': lectureTitle,
                      'slideText': slideText,
                      'prefilledMessage': 'Tell me more about "$topic" from slides $slideRange.',
                    },
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A2A3E), width: 1),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Slides $slideRange',
                              style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        topic,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}