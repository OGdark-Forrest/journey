import '../models/assessment.dart';
import '../models/day_info.dart';
import '../models/entry.dart';
import '../models/goal.dart';
import '../models/streak.dart';
import '../models/time_slot.dart';
import '../models/user_prefs.dart';

// Repository interfaces. UI/controllers depend on these only.
//
// MVP: implemented by the Mock* classes in `mock/`.
// TODO(backend): add `LocalApi*Repository` implementations that call the
// serious_python localhost server (see .kiro/steering/api-contract.md), then
// swap them in `AppDependencies` (lib/app/app_scope.dart). No UI changes needed.

abstract interface class AssessmentRepository {
  /// `GET /assessment/questions`
  Future<List<AssessmentQuestion>> fetchQuestions();

  /// `POST /assessment`
  Future<void> submit(List<AssessmentAnswer> answers);

  /// `GET /assessment/status`
  Future<bool> isCompleted();
}

abstract interface class JournalRepository {
  /// `GET /entries/draft`
  Future<EntryDraft> fetchDraft();

  /// `POST /entries`
  Future<SaveEntryResult> saveEntry(NewEntry entry);

  /// `GET /entries?from=&to=` (newest first)
  Future<List<LogEntry>> fetchEntries({required DateTime from, required DateTime to});

  /// `GET /streak`
  Future<StreakInfo> fetchStreak();

  /// `GET /day/{date}`
  Future<DayInfo> fetchDay(DateTime date);

  /// `PUT /day/{date}/wake-time`
  Future<DayInfo> saveWakeTime(DateTime date, FieldValue<TimeSlot> wakeTime);
}

/// Daily, weekly, and monthly goals. A goal is deleted once it is done.
abstract interface class GoalRepository {
  /// TODO(backend): `GET /goals`
  Future<List<Goal>> fetch();

  /// `POST /goals`
  Future<Goal> add(GoalPeriod period, String text);

  /// `DELETE /goals/{id}`
  Future<void> delete(String id);
}

/// Whether the user has paid for Premium (unlocks Insights).
// TODO(post-mvp): backed by the paywall / store purchase + cloud account.
abstract interface class PremiumRepository {
  Future<bool> isPremium();
  Future<void> setPremium(bool value);
}

abstract interface class PrefsRepository {
  /// `GET /prefs`
  Future<UserPrefs> fetch();

  /// `PUT /prefs`
  Future<UserPrefs> save(UserPrefs prefs);
}
