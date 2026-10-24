
class Authentication {
  final int userId;
  final String authMethod;
  final DateTime? lastLoginAt;

  const Authentication({
    required this.userId,
    required this.authMethod,
    this.lastLoginAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'authMethod': authMethod,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  factory Authentication.fromMap(Map<String, dynamic> map) {
    final String? lastLogin = map['lastLoginAt'] as String?;

    return Authentication(
      userId: map['userId'] as int,
      authMethod: map['authMethod'] as String,
      lastLoginAt:
          lastLogin == null ? null : DateTime.parse(lastLogin),
    );
  }
}
