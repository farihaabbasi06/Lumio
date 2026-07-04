class LectureModel {
  final String id;
  final String title;
  final String subjectId;
  final String summary;

  LectureModel({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.summary,
  });

  factory LectureModel.fromJson(Map<String, dynamic> json, String documentId) {
    return LectureModel(
      id: documentId,
      title: json['title'] ?? '',
      subjectId: json['subjectId'] ?? '',
      summary: json['summary'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subjectId': subjectId,
      'summary': summary,
    };
  }
}