import 'package:material_ui/material_ui.dart';

import '../../core/models/time_slot.dart';

/// Formats a [TimeSlot] using the device's locale and 12h/24h setting.
String formatSlot(BuildContext context, TimeSlot slot) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay(hour: slot.hour, minute: slot.minute),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}

/// "Today", "Yesterday", or e.g. "Tue, Oct 21".
String formatDayHeader(BuildContext context, DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(date.year, date.month, date.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return MaterialLocalizations.of(context).formatMediumDate(d);
}

/// Greeting based on the time of day.
String greetingFor(DateTime now) {
  final h = now.hour;
  if (h >= 5 && h < 12) return 'Good morning';
  if (h >= 12 && h < 17) return 'Good afternoon';
  if (h >= 17 && h < 22) return 'Good evening';
  return 'Hey there';
}
