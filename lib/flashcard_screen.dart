import 'package:flutter/material.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  bool _showAnswer = false; 
  int _currentIndex = 0;

  // 30 Comprehensive Technical & Academic Questions
  final List<Map<String, String>> _flashcards = [
    {'question': 'What is Flutter?', 'answer': 'Flutter is an open-source UI software development kit created by Google for building cross-platform applications.'},
    {'question': 'What is State Management?', 'answer': 'It is the way you manage and update the data/state that your application widgets depend on.'},
    {'question': 'What is the difference between Stateless and Stateful widgets?', 'answer': 'Stateless widgets are immutable and cannot change state at runtime. Stateful widgets maintain dynamic state via setState().'},
    {'question': 'What is the purpose of async and await in Dart?', 'answer': 'They handle asynchronous operations (like API calls) without blocking the main thread, keeping the UI responsive.'},
    {'question': 'What is a Future in Dart?', 'answer': 'A Future represents a potential value or error that will be available at some point in the time ahead.'},
    {'question': 'What is the difference between Hot Reload and Hot Restart?', 'answer': 'Hot Reload injects code updates into VM keeping state. Hot Restart destroys state and recompiles everything.'},
    {'question': 'What is an Intent in mobile app development?', 'answer': 'An Intent is an abstract description of an operation to be performed, mostly to launch activities or services.'},
    {'question': 'What is a Key in Flutter and why is it used?', 'answer': 'Keys are identifiers for Widgets. They preserve state when widgets move dynamically around the widget tree.'},
    {'question': 'What is the purpose of the pubspec.yaml file?', 'answer': 'It is the metadata configuration file where project dependencies, assets, fonts, and versions are explicitly defined.'},
    {'question': 'What is the role of the BuildContext?', 'answer': 'BuildContext handles the location of a widget inside the widget tree hierarchy structure.'},
    {'question': 'What is Software Reverse Engineering?', 'answer': 'The process of analyzing a software system to identify its components and interrelationships, often to extract source code or design.'},
    {'question': 'What is the difference between APK and AUB?', 'answer': 'APK (Android Package) is the final executable package for installation, while AAB (Android App Bundle) is a publishing format that optimizes APK generation for target devices.'},
    {'question': 'What is the purpose of a Stack in 8086 Assembly?', 'answer': 'A stack is a Last-In-First-Out (LIFO) memory segment used to store return addresses during functions/interrupts and temporarily hold register data.'},
    {'question': 'What is a Stream in Dart?', 'answer': 'A Stream provides an asynchronous sequence of data data-points over time (like multiple packets received over a network).'},
    {'question': 'What is the difference between Linear Algebra and regular algebra?', 'answer': 'Regular algebra deals with scalar numbers, while Linear Algebra deals with vectors, matrices, and linear transformations.'},
    {'question': 'What is an abstract class?', 'answer': 'A class that cannot be instantiated directly and is meant to define a blueprint/template for subclasses to implement.'},
    {'question': 'What is Polymorphism in OOP?', 'answer': 'The ability of different objects to respond to the same function call in their own specific ways (Overriding and Overloading).'},
    {'question': 'What is the purpose of Git Bash?', 'answer': 'A command-line interface environment that brings Git command-line tools to Windows environments.'},
    {'question': 'What is the difference between a Process and a Thread?', 'answer': 'A process is an executing program with its own memory space. A thread is a lightweight subset of a process sharing its memory.'},
    {'question': 'What is a REST API?', 'answer': 'An architectural style for providing web API services that communicate via standard HTTP requests (GET, POST, PUT, DELETE).'},
    {'question': 'What is an Opportunity Assessment Plan in Entrepreneurship?', 'answer': 'A systematic analysis of a business idea to see if it is viable, looking at market demand, competitor analysis, and resource needs.'},
    {'question': 'What is the role of the 8086 Instruction Pointer (IP)?', 'answer': 'The IP register holds the offset address of the next instruction bytes to be fetched and executed from the Code Segment.'},
    {'question': 'What is an operational plan?', 'answer': 'A detailed document mapping out day-to-day milestones, logistics, supply chain setups, and resource workflows for a business.'},
    {'question': 'What is a JSON format?', 'answer': 'JavaScript Object Notation, a lightweight data-interchange format that is completely text-based and easy for humans to read and write.'},
    {'question': 'What is a Widget Tree in Flutter?', 'answer': 'The structural tree hierarchy formed by nested UI components where layout definitions are declared.'},
    {'question': 'What is the role of the pub.dev repository?', 'answer': 'The official package management directory where developers share and download open-source plugins for Dart and Flutter.'},
    {'question': 'What is conditional styling in Flutter layouts?', 'answer': 'The technique of programmatically altering UI properties (like text color or visibility) based on logic conditions like specific data values.'},
    {'question': 'What is Git version control?', 'answer': 'A distributed tracking tool used to manage source code history, enabling multiple developers to collaborate without overwriting data.'},
    {'question': 'What is the difference between internal and external styling?', 'answer': 'Internal styling sits inside the same file boundary, while external styling keeps layout formatting declarations in separate dedicated rule sheets.'},
    {'question': 'What is the main goal of the SlideAsk Pro app?', 'answer': 'An AI study tool created to parse user PDFs and transform content into flashcards, visual maps, and predictive scores.'}
  ];

  void _toggleFlip() => setState(() => _showAnswer = !_showAnswer);
  
  void _nextCard() {
    setState(() {
      if (_currentIndex < _flashcards.length - 1) {
        _currentIndex++;
        _showAnswer = false;
      }
    });
  }

  void _previousCard() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
        _showAnswer = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentCard = _flashcards[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Flashcards Study Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange.shade400,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Card ${_currentIndex + 1} of ${_flashcards.length}', 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)
            ),
            const SizedBox(height: 25),
            GestureDetector(
              onTap: _toggleFlip,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                height: 320,
                decoration: BoxDecoration(
                  color: _showAnswer ? Colors.orange.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _showAnswer ? Colors.orange : Colors.grey.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                  ]
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _showAnswer ? 'ANSWER' : 'QUESTION', 
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: _showAnswer ? Colors.orange.shade800 : Colors.grey)
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _showAnswer ? currentCard['answer']! : currentCard['question']!, 
                        textAlign: TextAlign.center, 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _showAnswer ? Colors.orange.shade900 : Colors.black87, height: 1.4)
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 5),
                Text('Tap card to flip', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[500], fontSize: 13)),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _currentIndex > 0 ? _previousCard : null, 
                  icon: const Icon(Icons.arrow_back_ios), 
                  style: IconButton.styleFrom(backgroundColor: Colors.white, disabledBackgroundColor: Colors.grey[200])
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _nextCard,
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Wrong'),
                      style: ElevatedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _nextCard,
                      icon: const Icon(Icons.check, color: Colors.green),
                      label: const Text('Got It'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _currentIndex < _flashcards.length - 1 ? _nextCard : null, 
                  icon: const Icon(Icons.arrow_forward_ios), 
                  style: IconButton.styleFrom(backgroundColor: Colors.white, disabledBackgroundColor: Colors.grey[200])
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}