import 'package:flutter/material.dart';

class ExamPredictorScreen extends StatelessWidget {
  const ExamPredictorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Light aesthetic background
      appBar: AppBar(
        title: const Text(
          'Exam Predictor Screen', 
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade100, // Fixed error-free color shade
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top AI Success Prediction Card
            Card(
              elevation: 2,
              color: Colors.green.shade50, // Fixed color shade
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 24,
                      child: Icon(Icons.bolt, size: 28, color: Colors.green),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Success Probability', 
                          style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '85% Chance of A grade', 
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // 2. Section Heading Label
            const Text(
              'Topic Breakdown & Analysis', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            
            // 3. Polished Mastery Progress Bars
            _buildPredictorTile('Widgets & Layouts', 0.9, Colors.blue),
            _buildPredictorTile('State Management', 0.75, Colors.orange),
            _buildPredictorTile('Asynchronous Programming', 0.6, Colors.red),
            _buildPredictorTile('Networking & APIs', 0.88, Colors.purple),
            
            const SizedBox(height: 40),
            
            // 4. Smart Bottom Action Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Action handling here
                },
                icon: const Icon(Icons.assignment),
                label: const Text(
                  'Generate Smart Mock Exam', 
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Reusable component function for topic progress tracking lines
  Widget _buildPredictorTile(String topic, double score, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                topic, 
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
              ),
              Text(
                '${(score * 100).toInt()}% Mastery', 
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: score,
            color: color,
            backgroundColor: color.withOpacity(0.1), // Perfectly blends track color matching indicators
            minHeight: 10,
            borderRadius: BorderRadius.circular(6), // Smooth rounded corners
          ),
        ],
      ),
    );
  }
}