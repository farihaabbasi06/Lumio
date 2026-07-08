import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/subject_screen.dart';
import 'screens/lecture_detail_screen.dart';
import 'screens/chat_screen.dart'; // <-- 1. ADD THIS CHAT SCREEN IMPORT RIGHT HERE
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/flashcard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Hive.initFlutter();
  //await Firebase.initializeApp();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SharedPreferences.getInstance(); // add this line
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF534AB7),
      ),
      // Define the starting gate screen
      initialRoute: '/login',
      // Map out screen paths
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/lecture-detail': (context) => const LectureDetailScreen(),
        '/subject-detail': (context) => const SubjectScreen(),
        '/chat': (context) => const ChatScreen(), // <-- 2. ADD THIS PATH MAP LINE
        '/flashcards': (context) => const FlashcardScreen(),
      },
    );
  }
}