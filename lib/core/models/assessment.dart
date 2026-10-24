enum QuestionType {
  /// Pick a time (30-min steps). Options are quick picks; custom opens the full grid.
  time,

  /// Pick one option (+ optional custom text).
  single,

  /// Pick one or more options.
  multi,

  /// 1-5 scale.
  scale,

  /// Free text (e.g. name).
  text;

  static QuestionType fromApi(String value) =>
      QuestionType.values.firstWhere((t) => t.name == value, orElse: () => QuestionType.single);
}

/// From `GET /assessment/questions`.
class AssessmentQuestion {
  const AssessmentQuestion({
    required this.id,
    required this.prompt,
    required this.type,
    this.subtitle,
    this.options = const [],
    this.allowCustom = false,
    this.hint,
  });

  final String id;
  final String prompt;
  final String? subtitle;
  final QuestionType type;
  final List<String> options;
  final bool allowCustom;

  /// Placeholder for text / custom inputs.
  final String? hint;
}

/// One answer in `POST /assessment`. Multi-select answers are joined with ", ".
class AssessmentAnswer {
  const AssessmentAnswer({required this.questionId, required this.value, this.custom = false});

  final String questionId;
  final String value;
  final bool custom;
}
