class ReclamationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String? status;
  final String? imageUrl;
  final DateTime createdAt;

  const ReclamationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.status,
    this.imageUrl,
    required this.createdAt,
  });

  factory ReclamationModel.fromJson(Map<String, dynamic> json) {
    return ReclamationModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? json['id_user'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'PENDING',
      imageUrl: json['imageUrl'] ?? json['image'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'status': status,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
