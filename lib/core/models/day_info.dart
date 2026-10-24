import 'time_slot.dart';

/// From `GET /day/{date}`. Holds the once-a-day wake-up time, which is
/// separate from the `n` entries.
class DayInfo {
  const DayInfo({
    required this.date,
    required this.wakeTime,
    required this.wakeTimeDefault,
    this.intervalMinutes = 30,
  });

  final DateTime date;

  /// Null until the user confirms or changes it today.
  final TimeSlot? wakeTime;

  /// The user's standard wake time (from the assessment, then history).
  final TimeSlot wakeTimeDefault;
  final int intervalMinutes;

  bool get wakeTimeAnswered => wakeTime != null;
}
