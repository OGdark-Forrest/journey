class JournalEntry {
  final int? id;
  final String content;
  final String? promptText;
  final String createdAt;
  final String updatedAt;

  const JournalEntry({
    this.id,
    required this.content,
    this.promptText,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'content': content,
        'promptText': promptText,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory JournalEntry.fromMap(Map<String, Object?> map) => JournalEntry(
        id: map['id'] as int?,
        content: map['content'] as String,
        promptText: map['promptText'] as String?,
        createdAt: map['createdAt'] as String,
        updatedAt: map['updatedAt'] as String,
      );
}
