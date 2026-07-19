import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_widgets.dart';
import '../theme/app_colors.dart';

class MindMapScreen extends StatelessWidget {
  final String subjectId;
  final String lectureId;

  const MindMapScreen({
    super.key,
    required this.subjectId,
    required this.lectureId,
  });

  Color _getNodeColor(String colorName, AppColors colors) {
    switch (colorName.toLowerCase()) {
      case 'purple':
        return colors.primary;
      case 'blue':
        return const Color(0xFF3A86FF);
      case 'teal':
        return colors.accent;
      case 'amber':
        return const Color(0xFFFFB703);
      case 'rose':
        return const Color(0xFFFB5607);
      default:
        return colors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'Lecture Mind Map',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('lectures').doc(lectureId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colors.primary));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Lecture data not found.", style: TextStyle(color: colors.textSecondary)));
          }

          final lectureData = snapshot.data!.data() as Map<String, dynamic>?;
          if (lectureData == null) {
            return Center(child: Text("No data found.", style: TextStyle(color: colors.textSecondary)));
          }

          final List<dynamic> nodes = lectureData['mindMapNodes'] ?? [];
          final String slideText = lectureData['slideText'] ?? '';
          final String lectureTitle = lectureData['title'] ?? 'Lecture';

          if (nodes.isEmpty) {
            return const LumioEmptyState(
              icon: Icons.hub_outlined,
              title: 'No mind map yet',
              subtitle: 'Upload a new lecture to see topic clusters',
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
                final Color themeColor = _getNodeColor(node['color'] ?? 'purple', colors);

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
                      color: colors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: themeColor.withAlpha(80), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: themeColor.withAlpha(38),
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
                          style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
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