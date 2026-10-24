import '../../models/assessment.dart';
import '../../models/day_info.dart';
import '../../models/entry.dart';
import '../../models/streak.dart';
import '../../models/time_slot.dart';
import '../../models/user_prefs.dart';
import '../repositories.dart';
import 'mock_python_backend.dart';

// TODO(backend): replace each Mock*Repository with a LocalApi*Repository that
// calls the serious_python localhost server. Method-to-endpoint mapping is on
// the interfaces in ../repositories.dart.

class MockAssessmentRepository implements AssessmentRepository {
  MockAssessmentRepository(this._backend);
  final MockPythonBackend _backend;

  @override
  Future<List<AssessmentQuestion>> fetchQuestions() async {
    await _backend.roundTrip();
    return _backend.questions;
  }

  @override
  Future<void> submit(List<AssessmentAnswer> answers) async {
    await _backend.roundTrip();
    _backend.submitAssessment(answers);
  }

  @override
  Future<bool> isCompleted() async {
    await _backend.roundTrip();
    return _backend.assessmentCompleted;
  }
}

class MockJournalRepository implements JournalRepository {
  MockJournalRepository(this._backend);
  final MockPythonBackend _backend;

  @override
  Future<EntryDraft> fetchDraft(EntryMode mode) async {
    await _backend.roundTrip();
    return _backend.draft(mode);
  }

  @override
  Future<SaveEntryResult> saveEntry(NewEntry entry) async {
    await _backend.roundTrip();
    return _backend.save(entry);
  }

  @override
  Future<List<LogEntry>> fetchEntries({required DateTime from, required DateTime to}) async {
    await _backend.roundTrip();
    return _backend.entriesBetween(from, to);
  }

  @override
  Future<StreakInfo> fetchStreak() async {
    await _backend.roundTrip();
    return _backend.streak();
  }

  @override
  Future<DayInfo> fetchDay(DateTime date) async {
    await _backend.roundTrip();
    return _backend.day(date);
  }

  @override
  Future<DayInfo> saveWakeTime(DateTime date, FieldValue<TimeSlot> wakeTime) async {
    await _backend.roundTrip();
    return _backend.setWakeTime(date, wakeTime);
  }
}

class MockPrefsRepository implements PrefsRepository {
  MockPrefsRepository(this._backend);
  final MockPythonBackend _backend;

  @override
  Future<UserPrefs> fetch() async {
    await _backend.roundTrip();
    return _backend.prefs;
  }

  @override
  Future<UserPrefs> save(UserPrefs prefs) async {
    await _backend.roundTrip();
    _backend.prefs = prefs;
    return prefs;
  }
}
