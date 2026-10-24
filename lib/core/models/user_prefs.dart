import 'time_slot.dart';

enum ThemePreference { system, light, dark }

/// From `GET /prefs`. Small, local-only preferences (no account in MVP).
class UserPrefs {
  const UserPrefs({
    required this.displayName,
    required this.entriesPerDay,
    required this.reminderTime,
    required this.theme,
  });

  static const defaultEntriesPerDay = 10;
  static const minEntriesPerDay = 1;
  static const maxEntriesPerDay = 20;

  final String displayName;

  /// `n`: how many entries the user aims to log per day. Default 10.
  final int entriesPerDay;

  /// Null = reminders off.
  final TimeSlot? reminderTime;
  final ThemePreference theme;

  UserPrefs copyWith({
    String? displayName,
    int? entriesPerDay,
    TimeSlot? reminderTime,
    bool clearReminder = false,
    ThemePreference? theme,
  }) {
    return UserPrefs(
      displayName: displayName ?? this.displayName,
      entriesPerDay: entriesPerDay ?? this.entriesPerDay,
      reminderTime: clearReminder ? null : (reminderTime ?? this.reminderTime),
      theme: theme ?? this.theme,
    );
  }
}
