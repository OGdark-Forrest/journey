/// How far ahead a goal is planned.
enum GoalPeriod {
  daily,
  weekly,
  monthly;

  /// Section heading, e.g. "Daily goals".
  String get title => switch (this) {
        GoalPeriod.daily => 'Daily goals',
        GoalPeriod.weekly => 'Weekly goals',
        GoalPeriod.monthly => 'Monthly goals',
      };

  /// Lowercase word used in labels, e.g. "daily" in "Add daily goal".
  String get noun => name;
}

/// A to-do the user wants to do. It is deleted once the user checks it off.
class Goal {
  const Goal({required this.id, required this.period, required this.text});

  final String id;
  final GoalPeriod period;
  final String text;
}
