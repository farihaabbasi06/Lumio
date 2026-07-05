import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SlideAsk Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      // App central Hub Screen se start hogi jahan sab screens ke paths hain
      initialRoute: '/', 
      routes: {
        '/': (context) => const MainMenuScreen(),
        '/flashcard': (context) => const FlashcardScreen(),
        '/examPredictor': (context) => const ExamPredictorScreen(),
        '/mindMap': (context) => const MindMapScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

// =========================================================================
// 0. MAIN MENU HUB (Central Navigation Screen)
// =========================================================================
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SlideAsk Pro - UI Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade100, // Fixed Scheme
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Select a UI Screen to Test:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
            ),
            _buildMenuButton(context, '1. Flashcard Screen', '/flashcard', Icons.style, Colors.orange),
            const SizedBox(height: 12),
            _buildMenuButton(context, '2. Exam Predictor Screen', '/examPredictor', Icons.psychology, Colors.green),
            const SizedBox(height: 12),
            _buildMenuButton(context, '3. Mind Map Screen', '/mindMap', Icons.hub, Colors.purple),
            const SizedBox(height: 12),
            _buildMenuButton(context, '4. Profile Screen', '/profile', Icons.account_circle, Colors.teal),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, String routeName, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          Navigator.pushNamed(context, routeName);
        },
      ),
    );
  }
}

// =========================================================================
// 1. FLASHCARD SCREEN DESIGN CODE (With 10 robust questions)
// =========================================================================
class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  bool _showAnswer = false; 
  int _currentIndex = 0;

  final List<Map<String, String>> _flashcards = [
    {
      'question': 'What is Flutter?',
      'answer': 'Flutter is an open-source UI software development kit created by Google for building cross-platform applications.'
    },
    {
      'question': 'What is State Management?',
      'answer': 'It is the way you manage and update the data/state that your application widgets depend on.'
    },
    {
      'question': 'What is the difference between Stateless and Stateful widgets?',
      'answer': 'Stateless widgets are immutable and cannot change state at runtime. Stateful widgets maintain dynamic state via setState().'
    },
    {
      'question': 'What is the purpose of async and await in Dart?',
      'answer': 'They handle asynchronous operations (like API calls) without blocking the main thread, keeping the UI responsive.'
    },
    {
      'question': 'What is a Future in Dart?',
      'answer': 'A Future represents a potential value or error that will be available at some point in the time ahead.'
    },
    {
      'question': 'What is the difference between Hot Reload and Hot Restart?',
      'answer': 'Hot Reload injects code updates into VM keeping state. Hot Restart destroys state and recompiles everything.'
    },
    {
      'question': 'What is an Intent in mobile app development?',
      'answer': 'An Intent is an abstract description of an operation to be performed, mostly to launch activities or services.'
    },
    {
      'question': 'What is a Key in Flutter and why is it used?',
      'answer': 'Keys are identifiers for Widgets. They preserve state when widgets move dynamically around the widget tree.'
    },
    {
      'question': 'What is the purpose of the pubspec.yaml file?',
      'answer': 'It is the metadata configuration file where project dependencies, assets, fonts, and versions are explicitly defined.'
    },
    {
      'question': 'What is the role of the BuildContext?',
      'answer': 'BuildContext handles the location of a widget inside the widget tree hierarchy structure.'
    }
  ];

  void _toggleFlip() => setState(() => _showAnswer = !_showAnswer);
  void _nextCard() => setState(() { if (_currentIndex < _flashcards.length - 1) { _currentIndex++; _showAnswer = false; } });
  void _previousCard() => setState(() { if (_currentIndex > 0) { _currentIndex--; _showAnswer = false; } });

  @override
  Widget build(BuildContext context) {
    final currentCard = _flashcards[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Flashcards Study Hub'),
        backgroundColor: Colors.orange.shade400,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Card ${_currentIndex + 1} of ${_flashcards.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 25),
            GestureDetector(
              onTap: _toggleFlip,
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: _showAnswer ? Colors.orange.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _showAnswer ? Colors.orange : Colors.grey.shade300, width: 2),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_showAnswer ? 'ANSWER' : 'QUESTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _showAnswer ? Colors.orange.shade800 : Colors.grey)),
                    const SizedBox(height: 20),
                    Text(_showAnswer ? currentCard['answer']! : currentCard['question']!, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _showAnswer ? Colors.orange.shade900 : Colors.black87)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: _currentIndex > 0 ? _previousCard : null, icon: const Icon(Icons.arrow_back_ios), style: IconButton.styleFrom(backgroundColor: Colors.white)),
                ElevatedButton(onPressed: _nextCard, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text('Next Card')),
                IconButton(onPressed: _currentIndex < _flashcards.length - 1 ? _nextCard : null, icon: const Icon(Icons.arrow_forward_ios), style: IconButton.styleFrom(backgroundColor: Colors.white)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 2. EXAM PREDICTOR SCREEN DESIGN CODE (Fixed Background Colors)
// =========================================================================
class ExamPredictorScreen extends StatelessWidget {
  const ExamPredictorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Predictor Screen'),
        backgroundColor: Colors.green.shade100, // FIXED HERE
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.green.shade50, // FIXED HERE
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Icon(Icons.bolt, size: 40, color: Colors.green),
                    SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Success Probability', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        Text('85% Chance of A grade', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text('Topic Breakdown & Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildPredictorTile('Widgets & Layouts', 0.9, Colors.blue),
            _buildPredictorTile('State Management', 0.75, Colors.orange),
            _buildPredictorTile('Asynchronous Programming', 0.6, Colors.red),
            _buildPredictorTile('Networking & APIs', 0.88, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictorTile(String topic, double score, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(topic, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('${(score * 100).toInt()}% Mastery', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(value: score, color: color, backgroundColor: Colors.grey.shade200, minHeight: 8),
        ],
      ),
    );
  }
}

// =========================================================================
// 3. MIND MAP SCREEN DESIGN CODE (Fixed Background Colors)
// =========================================================================
class MindMapScreen extends StatelessWidget {
  const MindMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mind Map Screen'),
        backgroundColor: Colors.purple.shade100, // FIXED HERE
      ),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(12)),
                  child: const Text('Flutter Core Concepts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                const Text('Visual Map Rendering Connected Tree Structure...', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// 4. PROFILE SCREEN DESIGN CODE (Fixed Background Colors)
// =========================================================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Screen'),
        backgroundColor: Colors.teal.shade100, // FIXED HERE
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Center(
              child: CircleAvatar(radius: 50, backgroundColor: Colors.teal, child: Icon(Icons.person, size: 50, color: Colors.white)),
            ),
            const SizedBox(height: 15),
            const Text('Zamzam Ali', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('zamzam.ali@student.comsats.edu.pk', style: TextStyle(color: Colors.grey)),
            const Divider(height: 40),
            ListTile(leading: const Icon(Icons.bar_chart, color: Colors.teal), title: const Text('Academic Performance Check'), onTap: () {}),
            ListTile(leading: const Icon(Icons.settings, color: Colors.teal), title: const Text('Application Preferences'), onTap: () {}),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'profile_screen.dart'; // Humne nayi bani hui file ko yahan import kiya hai

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false, // Debug banner ko remove karne ke liye
      title: 'Profile App',
      home: ProfileScreen(), // Yahan se aapki polished profile screen call ho rahi hai
    );
  }
}