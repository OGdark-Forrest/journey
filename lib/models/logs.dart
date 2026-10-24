class AppLog {
  final int? id;
  final int? userId;
  final String action;
  final DateTime createdAt;

  AppLog({
    this.id,
    this.userId,
    required this.action,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'action': action,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppLog.fromMap(Map<String, dynamic> map) {
    return AppLog(
      id: map['id'] as int?,
      userId: map['userId'] as int?,
      action: map['action'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
