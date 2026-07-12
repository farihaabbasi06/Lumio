import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MindMapScreen extends StatelessWidget {
  final String subjectId;
  final String lectureId;

  const MindMapScreen({
    super.key,
    required this.subjectId,
    required this.lectureId,
  });

  Color _getNodeColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'purple': return const Color(0xFF534AB7);
      case 'blue': return const Color(0xFF3A86FF);
      case 'teal': return const Color(0xFF5DCAA5);
      case 'amber': return const Color(0xFFFFB703);
      case 'rose': return const Color(0xFFFB5607);
      default: return const Color(0xFF534AB7);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131324),
        elevation: 0,
        title: const Text(
          'Lecture Mind Map',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('lectures')
            .doc(lectureId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF534AB7)));
          }

          // SAFE CHECK: If anything goes wrong or document doesn't exist, fail gracefully without crashing
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Lecture data not found.", style: TextStyle(color: Colors.grey)));
          }

          final lectureData = snapshot.data!.data() as Map<String, dynamic>?;
          if (lectureData == null) {
            return const Center(child: Text("No data found.", style: TextStyle(color: Colors.grey)));
          }

          // SAFE CHECK: Safeguard against missing or legacy fields
          final List<dynamic> nodes = lectureData['mindMapNodes'] ?? [];
          final String slideText = lectureData['slideText'] ?? '';
          final String lectureTitle = lectureData['title'] ?? 'Lecture';

          // If this is an old lecture without mindmap data, show a friendly notice
          if (nodes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hub_outlined, size: 48, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  const Text("No mind map nodes generated yet.", style: TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text("Upload a new file to see this feature!", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              itemCount: nodes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final node = nodes[index] as Map<String, dynamic>;
                final String topic = node['topic'] ?? 'Unknown Topic';
                final String range = node['slideRange'] ?? 'N/A';
                final Color themeColor = _getNodeColor(node['color'] ?? 'purple');

                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/chat',
                      arguments: {
                        'subjectId': subjectId,
                        'lectureId': lectureId,
                        'lectureTitle': lectureTitle,
                        'slideText': slideText,
                        'initialMessage': "Tell me more about the topic '$topic' covering slides $range.",
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: themeColor.withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Slides $range",
                            style: TextStyle(color: themeColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          topic,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, color: themeColor, size: 14),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}