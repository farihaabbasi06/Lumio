import 'package:flutter/material.dart';

class ExamPredictorScreen extends StatefulWidget {
  const ExamPredictorScreen({super.key});

  @override
  State<ExamPredictorScreen> createState() => _ExamPredictorScreenState();
}

class _ExamPredictorScreenState extends State<ExamPredictorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _attendanceController = TextEditingController();
  final _midtermController = TextEditingController();
  String _resultMessage = "";

  void _predictResult() {
    if (_formKey.currentState!.validate()) {
      double attendance = double.parse(_attendanceController.text);
      double midterms = double.parse(_midtermController.text);

      // Ek simple aur mazedaar prediction logic
      setState(() {
        if (attendance < 75) {
          _resultMessage = "⚠️ Attendance kam hai (Shortage)! Pehle class puri karo.";
        } else if (midterms >= 25 && attendance >= 85) {
          _resultMessage = "🎉 Wah! A+ pakka hai. Tayari bhtreen chal rhi hai!";
        } else if (midterms >= 15) {
          _resultMessage = "👍 Mehnat karo, araam se clear ho jayega exam.";
        } else {
          _resultMessage = "📚 Danger Zone! Finals mai bohot zyada parhna parega.";
        }
      });
    }
  }

  @override
  void dispose() {
    _attendanceController.dispose();
    _midtermController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SlideAsk Pro - Exam Predictor'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Apne Academic Status Se Prediction Dekhein',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _attendanceController,
                decoration: const InputDecoration(
                  labelText: 'Attendance Percentage (%)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_month),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Attendance likhna lazmi hai';
                  double? val = double.tryParse(value);
                  if (val == null || val < 0 || val > 100) return 'Sahi percentage (0-100) likhein';
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _midtermController,
                decoration: const InputDecoration(
                  labelText: 'Midterm Marks',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.assessment),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Midterm ke marks likhein';
                  double? val = double.tryParse(value);
                  if (val == null || val < 0) return 'Sahi marks likhein';
                  return null;
                },
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _predictResult,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Predict My Result', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              const SizedBox(height: 30),
              if (_resultMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.deepPurple),
                  ),
                  child: Text(
                    _resultMessage,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.deepPurple),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}