class JournalPrompt {
  final int? id;
  final String promptText;
  final String category;
  final bool isActive;
  final int sortOrder;
  final String createdAt;

  const JournalPrompt({
    this.id,
    required this.promptText,
    required this.category,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'promptText': promptText,
        'category': category,
        'isActive': isActive ? 1 : 0,
        'sortOrder': sortOrder,
        'createdAt': createdAt,
      };

  factory JournalPrompt.fromMap(Map<String, Object?> map) => JournalPrompt(
        id: map['id'] as int?,
        promptText: map['promptText'] as String,
        category: map['category'] as String,
        isActive: (map['isActive'] as int) == 1,
        sortOrder: map['sortOrder'] as int,
        createdAt: map['createdAt'] as String,
      );
}
