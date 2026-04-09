class NotificationModel {
  final String id;
  final String userId;
  final String message;
  final String status;
  final String? title;
  final String? type;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.message,
    required this.status,
    this.title,
    this.type,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'UNREAD',
      title: json['title'] as String?,
      type: json['type'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'])
          : null,
    );
  }

  bool get isRead => status == 'READ';

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'message': message,
      'status': status,
      'title': title,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }
}
