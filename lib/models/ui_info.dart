
class UiInfo {
  final int? id;
  final int userId;
  final bool isDarkMode;

  const UiInfo({
    this.id,
    required this.userId,
    required this.isDarkMode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'isDarkMode': isDarkMode ? 1 : 0,
    };
  }

  factory UiInfo.fromMap(Map<String, dynamic> map) {
    return UiInfo(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      isDarkMode: (map['isDarkMode'] as int) == 1,
    );
  }
}
