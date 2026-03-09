class AdminNotificationModel {
  final int id;
  final String message;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminNotificationModel({
    required this.id,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminNotificationModel.fromJson(Map<String, dynamic> json) {
    return AdminNotificationModel(
      id: (json['id'] ?? 0) as int,
      message: (json['message'] ?? '').toString(),
      isRead: (json['isRead'] ?? false) as bool,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  AdminNotificationModel copyWith({
    int? id,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminNotificationModel(
      id: id ?? this.id,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  AdminNotificationModel copyWithForRead() {
    return copyWith(isRead: true);
  }
}