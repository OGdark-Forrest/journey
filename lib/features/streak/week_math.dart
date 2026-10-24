import '../../core/models/entry.dart';

/// Monday 00:00 (local) of the week containing [date].
///
/// Built from calendar fields rather than subtracting Durations, so DST
/// transitions can't shift the result by an hour.
DateTime mondayOf(DateTime date) => DateTime(date.year, date.month, date.day - (date.weekday - DateTime.monday));

/// The 7 local calendar days (Mon..Sun) of the week containing [date].
List<DateTime> weekOf(DateTime date) {
  final monday = mondayOf(date);
  return [for (var i = 0; i < 7; i++) DateTime(monday.year, monday.month, monday.day + i)];
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Days of [week] that have at least one entry.
Set<DateTime> loggedDaysIn(List<DateTime> week, Iterable<LogEntry> entries) {
  final days = week.toSet();
  return {
    for (final e in entries)
      if (days.contains(dateOnly(e.date))) dateOnly(e.date),
  };
}
