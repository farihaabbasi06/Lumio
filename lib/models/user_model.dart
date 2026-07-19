class UserModel {
  final String id;
  final String name;
  final String email;
  final String university;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.university,
  });

  // Converts Firestore JSON map into our Flutter UserModel object
  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      id: documentId,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      university: json['university'] ?? '',
    );
  }

  // Converts our Flutter UserModel object back into a JSON map to save to Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'university': university,
    };
  }
}