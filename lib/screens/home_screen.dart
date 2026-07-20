import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'exam_predictor_screen.dart';
import 'global_flashcards_view.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  final List<Widget> _pages = [
    const SubjectsDashboardView(),
    const GlobalFlashcardsView(),
    const ExamPredictorScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _currentIndex == 0
          ? AppBar(
              backgroundColor: colors.surface,
              elevation: 0,
              title: Text(
                'Lumio Study',
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.logout_outlined, color: colors.textPurple == Colors.white ? colors.primary : colors.textPurple),
                  onPressed: () async {
                    final box = await Hive.openBox('flashcards');
                    await box.clear();
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                ),
              ],
            )
          : null,
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textSecondary,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.layers_rounded), label: 'Flashcards'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology_rounded), label: 'Exam AI'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () => _showAddSubjectDialog(context, colors),
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }

  void _showAddSubjectDialog(BuildContext context, AppColors colors) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('New Subject', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: textController,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g., Mobile App Development',
              hintStyle: TextStyle(color: colors.textSecondary),
              filled: true,
              fillColor: colors.inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final subjectName = textController.text.trim();
                if (subjectName.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('subjects').add({
                    'name': subjectName,
                    'userId': _currentUserId,
                    'progress': 0.35,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: Text('Create', style: TextStyle(color: colors.textPurple)),
            ),
          ],
        );
      },
    );
  }
}

class SubjectsDashboardView extends StatelessWidget {
  const SubjectsDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('subjects')
          .where('userId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: colors.primary));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No subjects added yet.\nTap + to start!',
                textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary, fontSize: 16)),
          );
        }

        final subjectDocs = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.95,
          ),
          itemCount: subjectDocs.length,
          itemBuilder: (context, index) {
            final doc = subjectDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final String subjectName = data['name'] ?? 'Unnamed Subject';
            double progress = (data['progress'] ?? 0.0).toDouble();
            if (progress > 1.0) progress = progress / 100;

            // Rotate a friendly accent color per card, like the reference designs
            final List<Color> cardAccents = [colors.primary, colors.accent, colors.warning, const Color(0xFF3A86FF)];
            final Color cardAccent = cardAccents[index % cardAccents.length];

            return GestureDetector(
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: colors.card,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text('Delete Subject',
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
                    content: Text(
                      'Delete "$subjectName"? All lectures, flashcards and data inside will be permanently deleted.',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);

                          final lectures = await FirebaseFirestore.instance
                              .collection('lectures')
                              .where('subjectId', isEqualTo: doc.id)
                              .get();

                          for (var lecture in lectures.docs) {
                            final flashcards = await FirebaseFirestore.instance
                                .collection('flashcards')
                                .where('lectureId', isEqualTo: lecture.id)
                                .get();
                            for (var f in flashcards.docs) f.reference.delete();

                            final weakspots = await FirebaseFirestore.instance
                                .collection('weakspots')
                                .where('lectureId', isEqualTo: lecture.id)
                                .get();
                            for (var w in weakspots.docs) w.reference.delete();

                            await lecture.reference.delete();
                          }

                          await FirebaseFirestore.instance.collection('subjects').doc(doc.id).delete();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Subject deleted successfully'),
                                backgroundColor: colors.danger,
                              ),
                            );
                          }
                        },
                        child: Text('Delete', style: TextStyle(color: colors.danger, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/subject-detail',
                  arguments: {'subjectId': doc.id, 'subjectName': subjectName},
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(22),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cardAccent.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.folder_open_rounded, color: cardAccent, size: 24),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          subjectName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Progress', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                            Text('${(progress * 100).toInt()}%',
                                style: TextStyle(color: cardAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: colors.inputFill,
                            valueColor: AlwaysStoppedAnimation<Color>(cardAccent),
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}