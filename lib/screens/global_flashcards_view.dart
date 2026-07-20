import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';

class GlobalFlashcardsView extends StatelessWidget {
  const GlobalFlashcardsView({super.key});

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
          'Your Flashcard Decks',
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
            return Center(child: CircularProgressIndicator(color: colors.primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading data: ${snapshot.error}', style: TextStyle(color: colors.danger)),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];

          final deckDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data.containsKey('flashcards') &&
                data['flashcards'] != null &&
                data['flashcards'].toString().trim().isNotEmpty;
          }).toList();

          if (deckDocs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No flashcard decks found.\n\nMake sure you have uploaded a lecture PDF and that the AI processing has completely finished!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.5),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deckDocs.length,
            itemBuilder: (context, index) {
              final doc = deckDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String title = data['title'] ?? data['name'] ?? 'Untitled Deck';
              final int slideCount = data['pageCount'] ?? data['slides'] ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.layers_rounded, color: colors.primary, size: 24),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Text(
                    '$slideCount slides processed',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/flashcards',
                      arguments: {
                        'lectureId': doc.id,
                        'lectureTitle': title,
                        'subjectId': data['subjectId'] ?? '',
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}