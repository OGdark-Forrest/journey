import 'package:flutter/foundation.dart';

import '../../core/models/entry.dart';
import '../../core/models/time_slot.dart';
import '../../core/repositories/repositories.dart';

/// Holds the prewritten draft and the user's edits to its 3 fields.
/// "Kept default" is derived by comparing each value to the draft default.
class LogEntryController extends ChangeNotifier {
  LogEntryController(this._journal, {required EntryMode mode}) : _mode = mode;

  final JournalRepository _journal;

  EntryMode _mode;
  EntryMode get mode => _mode;

  EntryDraft? _draft;
  EntryDraft? get draft => _draft;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  bool _saving = false;
  bool get saving => _saving;

  late TimeSlot _time;
  late int _happiness;
  late String _event;
  bool _eventCustom = false;

  TimeSlot get time => _time;
  int get happiness => _happiness;
  String get event => _event;
  bool get eventCustom => _eventCustom;

  bool get timeIsDefault => _draft != null && _time == _draft!.timeDefault;
  bool get happinessIsDefault => _draft != null && _happiness == _draft!.happinessDefault;
  bool get eventIsDefault => _draft != null && !_eventCustom && _event == _draft!.eventDefault;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final d = await _journal.fetchDraft(_mode);
      _draft = d;
      _time = d.timeDefault;
      _happiness = d.happinessDefault;
      _event = d.eventDefault;
      _eventCustom = false;
    } catch (e) {
      _error = 'Couldn\'t prepare your entry.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Switching modes fetches a fresh draft for that mode.
  Future<void> setMode(EntryMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    await load();
  }

  void setTime(TimeSlot t) {
    _time = t;
    notifyListeners();
  }

  void setHappiness(int v) {
    _happiness = v;
    notifyListeners();
  }

  void setEvent(String value, {bool custom = false}) {
    _event = value.trim();
    _eventCustom = custom;
    notifyListeners();
  }

  void resetTime() => setTime(_draft!.timeDefault);
  void resetHappiness() => setHappiness(_draft!.happinessDefault);
  void resetEvent() => setEvent(_draft!.eventDefault);

  bool get canSave => _draft != null && !_saving && _event.isNotEmpty;

  Future<SaveEntryResult?> save() async {
    final d = _draft;
    if (d == null || !canSave) return null;
    _saving = true;
    notifyListeners();
    try {
      return await _journal.saveEntry(NewEntry(
        draftId: d.draftId,
        mode: _mode,
        time: FieldValue(value: _time, keptDefault: timeIsDefault),
        happiness: FieldValue(value: _happiness, keptDefault: happinessIsDefault),
        event: FieldValue(value: _event, keptDefault: eventIsDefault, custom: _eventCustom),
      ));
    } catch (e) {
      _error = 'Couldn\'t save. Please try again.';
      return null;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}

/// Confetti is saved for moments that matter so it doesn't get noisy:
/// the first entry of the day (streak kept) and hitting the daily goal.
bool shouldCelebrate(SaveEntryResult r) =>
    r.indexToday == r.streak.streakMinEntries || r.indexToday == r.streak.entriesPerDay;
