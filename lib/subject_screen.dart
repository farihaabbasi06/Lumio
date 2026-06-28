import 'package:flutter/material.dart';
import 'chat_screen.dart';

class SubjectScreen extends StatelessWidget {
  const SubjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D18),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D18),
        elevation: 0,
        title: const Text(
          "Operating Systems",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Uploaded Slides",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              lectureCard("Lecture 1", "Introduction to Operating Systems"),
              const SizedBox(height: 15),
              lectureCard("Lecture 2", "Process Management"),
              const SizedBox(height: 15),
              lectureCard("Lecture 3", "Deadlocks"),

              const SizedBox(height: 30),

              const Text(
                "Study Tools",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: actionButton(Icons.summarize, "Summary", () {}),
                  ),
                  const SizedBox(width: 15),
                  Expanded(child: actionButton(Icons.quiz, "Quiz", () {})),
                ],
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: actionButton(Icons.style, "Flashcards", () {}),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: actionButton(Icons.smart_toy, "Ask AI", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatScreen()),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF534AB7),
        onPressed: () {},
        child: const Icon(Icons.upload_file),
      ),
    );
  }

  Widget lectureCard(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: Colors.red),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget actionButton(IconData icon, String text, VoidCallback onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF534AB7),
        minimumSize: const Size(double.infinity, 60),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
    );
  }
}
