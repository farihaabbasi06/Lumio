import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Theme Colors matching your exact palette
  static const backgroundColor = Color(0xFF0D0D18);
  static const cardColor = Color(0xFF1A1A2E);
  static const primaryPurple = Color(0xFF534AB7);
  static const accentNeon = Color(0xFF5DCAA5); // Mint accent color for progress from prototype
  static const textPurple = Color(0xFFCECBF6);

  // Temporary placeholder screens for other bottom tabs
  final List<Widget> _pages = [
    const SubjectsDashboardView(),
    const Center(child: Text('Flashcards Screen', style: TextStyle(color: Colors.white, fontSize: 18))),
    const Center(child: Text('Exam AI Screen', style: TextStyle(color: Colors.white, fontSize: 18))),
    const Center(child: Text('Profile Screen', style: TextStyle(color: Colors.white, fontSize: 18))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _currentIndex == 0
          ? AppBar(
              backgroundColor: const Color(0xFF131324),
              elevation: 0,
              title: const Text(
                'Lumio Study',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_outlined, color: textPurple),
                  onPressed: () async {
                    await AuthService().signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            )
          : null,
      body: _pages[_currentIndex],
      
      // STEP 4: Add Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF131324),
        selectedItemColor: primaryPurple,
        unselectedItemColor: Colors.grey,
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
      
      // STEP 2: Add New Subject Button
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () => _showAddSubjectDialog(context),
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }

  // Dialog method to add new subjects to firestore
  void _showAddSubjectDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('New Subject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: textController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g., Mobile App Development',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF252542),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final subjectName = textController.text.trim();
                if (subjectName.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('subjects').add({
                    'name': subjectName,
                    'userId': _currentUserId,
                    'progress': 0.35, // Setting a dummy default progress display percentage (e.g. 35%)
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Create', style: TextStyle(color: textPurple)),
            ),
          ],
        );
      },
    );
  }
}

// Separate Sub-Widget for the core Dashboard content grid view
class SubjectsDashboardView extends StatelessWidget {
  const SubjectsDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      // Filter subjects belonging only to the currently logged in student
      stream: FirebaseFirestore.instance
          .collection('subjects')
          .where('userId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _HomeScreenState.primaryPurple));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No subjects added yet.\nTap + to start!',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
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
            final double progress = (data['progress'] ?? 0.0).toDouble();

            return GestureDetector(
              onTap: () {
                // Navigate into specific subject page view passing along parameters
                Navigator.pushNamed(
                  context,
                  '/subject-detail',
                  arguments: {'subjectId': doc.id, 'subjectName': subjectName},
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _HomeScreenState.cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon and Title Header Layout
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF252542),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.folder_open_rounded, color: _HomeScreenState.primaryPurple, size: 24),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          subjectName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    // Progress bar indicator design
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Progress', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            Text('${(progress * 100).toInt()}%',
                                style: const TextStyle(color: _HomeScreenState.accentNeon, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: const Color(0xFF252542),
                            valueColor: const AlwaysStoppedAnimation<Color>(_HomeScreenState.accentNeon),
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