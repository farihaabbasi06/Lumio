import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/subject_screen.dart';
import 'screens/lecture_detail_screen.dart';
import 'screens/chat_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/flashcard_screen.dart';
import 'screens/weak_spots_screen.dart';
import 'screens/mindmap_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/exam_predictor_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';


import 'screens/exam_sim_setup_screen.dart';
import 'screens/exam_sim_screen.dart';
import 'screens/exam_sim_result_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Hive.initFlutter();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SharedPreferences.getInstance();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Lumio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode, // swaps live when toggled in Profile
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/lecture-detail': (context) => const LectureDetailScreen(),
        '/subject-detail': (context) => const SubjectScreen(),
        '/chat': (context) => const ChatScreen(),
        '/flashcards': (context) => const FlashcardScreen(),
        '/weakspots': (context) => const WeakSpotsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/exam-predictor': (context) => const ExamPredictorScreen(),
        '/mindmap': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
          return MindMapScreen(
            subjectId: args['subjectId'] ?? '',
            lectureId: args['lectureId'] ?? '',
          );
        },


        '/exam-sim-setup': (context) => const ExamSimSetupScreen(),
'/exam-sim': (context) => const ExamSimScreen(),
'/exam-sim-result': (context) => const ExamSimResultScreen(),
      },
    );
  }
}