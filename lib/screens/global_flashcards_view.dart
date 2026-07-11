import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GlobalFlashcardsView extends StatelessWidget {
  const GlobalFlashcardsView({super.key});

  static const backgroundColor = Color(0xFF0D0D18);
  static const cardColor = Color(0xFF1A1A2E);
  static const primaryPurple = Color(0xFF534AB7);
  static const textPurple = Color(0xFFCECBF6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF131324),
        elevation: 0,
        title: const Text(
          'Your Flashcard Decks',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('lectures').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryPurple));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading data: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];

          // Filters out items that don't have flashcards data populated yet
          final deckDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data.containsKey('flashcards') && 
                   data['flashcards'] != null && 
                   data['flashcards'].toString().trim().isNotEmpty;
          }).toList();

          if (deckDocs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No flashcard decks found.\n\nMake sure you have uploaded a lecture PDF and that the AI processing has completely finished!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
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
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF22223B), width: 1),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252542),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.layers_rounded, color: primaryPurple, size: 24),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Text(
                    '$slideCount slides processed',
                    style: const TextStyle(color: textPurple, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () {
                    // Fixed: Sending arguments as a Map structure containing both keys
                    Navigator.pushNamed(
                      context,
                      '/flashcards', 
                      arguments: {
                        'lectureId': doc.id,
                        'lectureTitle': title,
                        'subjectId': data['subjectId'] ?? '', // Safely forwards the subject link from the lecture document!
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