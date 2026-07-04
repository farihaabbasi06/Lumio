import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectScreen extends StatelessWidget {
  const SubjectScreen({super.key});

  // Reusing your exact dark purple neon palette colors
  static const backgroundColor = Color(0xFF0D0D18);
  static const cardColor = Color(0xFF1A1A2E);
  static const primaryPurple = Color(0xFF534AB7);
  static const accentNeon = Color(0xFF5DCAA5);
  static const orangeWarn = Color(0xFFEF9F27);
  static const textPurple = Color(0xFFCECBF6);

  @override
  Widget build(BuildContext context) {
    // Catch arguments passed during navigation route changes
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String subjectId = args['subjectId'] ?? '';
    final String subjectName = args['subjectName'] ?? 'Subject View';

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
          subjectName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. STATS ROW - Styled directly from your design prototype layout
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                _buildStatCard('7', 'Lectures', primaryPurple),
                _buildStatCard('312', 'Slides', accentNeon),
                _buildStatCard('48', 'Flashcards', orangeWarn),
                _buildStatCard('2', 'Weak spots', const Color(0xFFE24B4A)),
              ],
            ),
            const SizedBox(height: 16),

            // 2. STUDY ENTIRE SUBJECT INTERACTIVE AI CARD
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1228),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3C3489), width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3C3489),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.psychology_outlined, color: textPurple),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Study entire subject with AI', style: TextStyle(color: Color(0xFFAFA9EC), fontWeight: FontWeight.bold, fontSize: 13)),
                        SizedBox(height: 2),
                        Text('Ask questions across all lectures', style: TextStyle(color: primaryPurple, fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.auto_awesome, color: primaryPurple, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. LECTURES HEADER SECTION LABEL
            const Text(
              'LECTURES',
              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),

            // 4. STREAMBUILDER LECTURES STREAM FILTERED BY subjectId
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('lectures')
                  .where('subjectId', isEqualTo: subjectId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryPurple));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Text('No lectures uploaded yet.', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                final lectureDocs = snapshot.data!.docs;

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lectureDocs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = lectureDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final String title = data['title'] ?? 'L${index + 1}';
                    final String summary = data['summary'] ?? 'No summary available';

                    return Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF252542),
                          foregroundColor: primaryPurple,
                          child: Text('L${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: Text(summary, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                        onTap: () {
                          // Placeholder step route to move onto the individual lecture interaction section later
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Opening $title...')),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Dashboard Stat Card Helper block matching visual styling design spec
  Widget _buildStatCard(String value, String label, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(color: accentColor, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}