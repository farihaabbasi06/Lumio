import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'flashcard_screen.dart';
import 'exam_predictor_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SlideAsk Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const profile_screen(), 
    );
  }
}