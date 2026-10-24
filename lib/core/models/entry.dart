import 'streak.dart';
import 'time_slot.dart';

/// A prewritten entry from `GET /entries/draft`. One entry = one event, with
/// exactly 3 fields: time, happiness, event. See .kiro/steering/api-contract.md.
class EntryDraft {
  const EntryDraft({
    required this.draftId,
    required this.template,
    required this.timeDefault,
    required this.intervalMinutes,
    required this.happinessMin,
    required this.happinessMax,
    required this.happinessDefault,
    required this.eventDefault,
    required this.eventOptions,
    required this.allowCustom,
  });

  final String draftId;

  /// Sentence with `{time}`, `{event}`, `{happiness}` tokens rendered as chips.
  final String template;

  final TimeSlot timeDefault;
  final int intervalMinutes;

  final int happinessMin;
  final int happinessMax;
  final int happinessDefault;

  final String eventDefault;

  /// ~4 presets. A 5th "custom" option is offered when [allowCustom] is true.
  final List<String> eventOptions;
  final bool allowCustom;
}

/// A submitted field value plus whether the user kept the predicted default.
/// `keptDefault` is the signal the algorithm learns from.
class FieldValue<T> {
  const FieldValue({required this.value, required this.keptDefault, this.custom = false});

  final T value;
  final bool keptDefault;

  /// True when the user typed their own value instead of picking a preset.
  final bool custom;
}

/// Body for `POST /entries`.
class NewEntry {
  const NewEntry({
    required this.draftId,
    required this.time,
    required this.happiness,
    required this.event,
  });

  final String draftId;
  final FieldValue<TimeSlot> time;
  final FieldValue<int> happiness;
  final FieldValue<String> event;
}

/// Response from `POST /entries`.
class SaveEntryResult {
  const SaveEntryResult({required this.entryId, required this.indexToday, required this.streak});

  final String entryId;

  /// 1-based count of entries saved today, including this one.
  final int indexToday;
  final StreakInfo streak;
}

/// A saved entry, as listed in the dashboard log history (`GET /entries`).
class LogEntry {
  const LogEntry({
    required this.entryId,
    required this.date,
    required this.time,
    required this.happiness,
    required this.event,
    required this.text,
  });

  final String entryId;

  /// Calendar day (time component ignored).
  final DateTime date;
  final TimeSlot time;
  final int happiness;
  final String event;

  /// Final rendered journal sentence.
  final String text;
}
