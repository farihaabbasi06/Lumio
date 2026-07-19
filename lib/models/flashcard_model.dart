class FlashcardModel {
  final String id;
  final String question;
  final String answer;
  final String lectureId;

  FlashcardModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.lectureId,
  });

  factory FlashcardModel.fromJson(Map<String, dynamic> json, String documentId) {
    return FlashcardModel(
      id: documentId,
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      lectureId: json['lectureId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
      'lectureId': lectureId,
    };
  }
}