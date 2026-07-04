class WeakspotModel {
  final String id;
  final String topic;
  final int reviewCount;
  final String userId;

  WeakspotModel({
    required this.id,
    required this.topic,
    required this.reviewCount,
    required this.userId,
  });

  factory WeakspotModel.fromJson(Map<String, dynamic> json, String documentId) {
    return WeakspotModel(
      id: documentId,
      topic: json['topic'] ?? '',
      reviewCount: (json['reviewCount'] ?? 0 as num).toInt(),
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topic': topic,
      'reviewCount': reviewCount,
      'userId': userId,
    };
  }
}