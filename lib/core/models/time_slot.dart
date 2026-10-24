/// A time of day snapped to a fixed interval (30 min by default).
///
/// Pure Dart on purpose so models stay UI-free. Format for display with
/// `formatSlot()` in `shared/widgets/time_format.dart`, which respects the
/// device's 12h/24h setting.
class TimeSlot implements Comparable<TimeSlot> {
  const TimeSlot(this.minutes) : assert(minutes >= 0 && minutes < 24 * 60);

  const TimeSlot.hm(int hour, int minute) : this(hour * 60 + minute);

  /// Minutes since midnight.
  final int minutes;

  int get hour => minutes ~/ 60;
  int get minute => minutes % 60;

  /// Parses the API format `HH:mm`.
  factory TimeSlot.parse(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) throw FormatException('Expected HH:mm', hhmm);
    return TimeSlot.hm(int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Current time rounded down to the nearest [intervalMinutes].
  factory TimeSlot.nowRounded({int intervalMinutes = 30, DateTime? now}) {
    final t = now ?? DateTime.now();
    final m = t.hour * 60 + t.minute;
    return TimeSlot(m - (m % intervalMinutes));
  }

  /// Every slot in a day, e.g. 48 slots for a 30-minute interval.
  static List<TimeSlot> allSlots({int intervalMinutes = 30}) => [
        for (var m = 0; m < 24 * 60; m += intervalMinutes) TimeSlot(m),
      ];

  /// API format `HH:mm`.
  String toApi() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Plain 12h label used where no BuildContext exists (e.g. mock-generated text).
  String toLabel12h() {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final suffix = hour < 12 ? 'AM' : 'PM';
    return '$h:${minute.toString().padLeft(2, '0')} $suffix';
  }

  @override
  int compareTo(TimeSlot other) => minutes.compareTo(other.minutes);

  @override
  bool operator ==(Object other) => other is TimeSlot && other.minutes == minutes;

  @override
  int get hashCode => minutes.hashCode;

  @override
  String toString() => 'TimeSlot(${toApi()})';
}
