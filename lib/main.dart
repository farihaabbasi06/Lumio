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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ExamPredictorScreen(), 
    );
  }
}

// === Exam Predictor Screen UI ===
class ExamPredictorScreen extends StatefulWidget {
  const ExamPredictorScreen({super.key});

  @override
  State<ExamPredictorScreen> createState() => _ExamPredictorScreenState();
}

class _ExamPredictorScreenState extends State<ExamPredictorScreen> {
  final _formKey = GlobalKey<FormState>();
  String _predictionResult = "";
  bool _isAnalyzing = false;

  // Controllers to get text from inputs
  final _topicController = TextEditingController();
  final _attendanceController = TextEditingController();

  void _predictExamQuestions() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isAnalyzing = true;
      });

      // Simulating AI analysis delay
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isAnalyzing = false;
          _predictionResult = "🎯 Predicted High-Probability Topics for '${_topicController.text}':\n\n"
              "1. Core Concepts & Definitions (85% Probability)\n"
              "2. Practical Application & Case Studies (70% Probability)\n"
              "3. Past Papers Repeated Patterns (65% Probability)\n\n"
              "💡 Tip: Focus heavily on diagrams and lab implementation!";
        });
      });
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _attendanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SlideAsk Pro - Exam Predictor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.psychology, size: 40, color: Colors.deepPurple),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Enter your study details below, and our AI will predict your exam focus areas!',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Subject / Topic Input
                TextFormField(
                  controller: _topicController,
                  decoration: const InputDecoration(
                    labelText: 'Subject or Topic Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.book),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a subject or topic';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Attendance / Preparation Level Input
                TextFormField(
                  controller: _attendanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Your Preparation Level (1-100%)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.trending_up),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your preparation percentage';
                    }
                    final score = int.tryParse(value);
                    if (score == null || score < 1 || score > 100) {
                      return 'Enter a valid percentage between 1 and 100';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Predict Button
                ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _predictExamQuestions,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  icon: _isAnalyzing 
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Icon(Icons.analytics),
                  label: Text(_isAnalyzing ? 'Analyzing Data...' : 'Predict Exam Focus'),
                ),
                const SizedBox(height: 24),

                // Result Display
                if (_predictionResult.isNotEmpty)
                  Card(
                    color: Colors.deepPurple.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.deepPurple, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _predictionResult,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}