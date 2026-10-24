/// From `GET /streak`. The server owns the streak rule; the UI only renders it.
class StreakInfo {
  const StreakInfo({
    required this.current,
    required this.best,
    required this.loggedToday,
    required this.entriesPerDay,
    required this.streakMinEntries,
  });

  final int current;
  final int best;
  final int loggedToday;
  final int entriesPerDay;

  /// Entries needed for a day to count toward the streak (config, default 1).
  final int streakMinEntries;

  bool get todayCounts => loggedToday >= streakMinEntries;
  bool get dailyGoalReached => loggedToday >= entriesPerDay;
  double get todayProgress =>
      entriesPerDay == 0 ? 0 : (loggedToday / entriesPerDay).clamp(0.0, 1.0);
}
