class SubjectModel {
  final String id;
  final String name;
  final String userId;

  SubjectModel({
    required this.id,
    required this.name,
    required this.userId,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json, String documentId) {
    return SubjectModel(
      id: documentId,
      name: json['name'] ?? '',
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'userId': userId,
    };
  }
}