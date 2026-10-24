import 'package:flutter/widgets.dart';

import '../core/models/insight.dart';
import '../core/python/python_runtime.dart';
import '../core/repositories/insight_request.dart';
import '../core/repositories/mock/mock_python_backend.dart';
import '../core/repositories/local/journey_database.dart';
import '../core/repositories/local/sqflite_repositories.dart';
import '../core/repositories/mock/mock_repositories.dart';
import '../core/repositories/repositories.dart';
import '../core/storage/launch_mood.dart';
import 'app_controller.dart';

/// Per-launch UI state that must outlive a single screen (screens can be
/// rebuilt, e.g. after retaking the assessment). Resets on app restart.
class SessionState {
  /// The user closed the Premium banner during this launch.
  bool premiumBannerDismissed = false;

  /// Generated reflections / plans keyed by kind + day, so leaving and
  /// reopening a page doesn't pay for another model call.
  final Map<(InsightKind, DateTime), Insight> insights = {};
}

/// Everything screens need, created once at startup.
class AppDependencies {
  AppDependencies({
    required this.python,
    required this.assessment,
    required this.journal,
    required this.prefs,
    required this.premium,
    required this.goals,
    required this.insights,
    required this.launchMood,
  }) : app = AppController(python: python, assessment: assessment, prefs: prefs);

  /// MVP wiring: fake Python runtime + in-memory mock backend.
  // TODO(backend): add `AppDependencies.local()` that builds a
  // SeriousPythonRuntime and LocalApi*Repository instances sharing its
  // baseUrl/token, and use it in main.dart.
  factory AppDependencies.mock({Duration latency = const Duration(milliseconds: 250)}) {
    final backend = MockPythonBackend(latency: latency);
    final assessment = MockAssessmentRepository(backend);
    final journal = MockJournalRepository(backend);
    final goals = MockGoalRepository(backend);
    return AppDependencies(
      python: MockPythonRuntime(),
      assessment: assessment,
      journal: journal,
      prefs: MockPrefsRepository(backend),
      premium: MockPremiumRepository(),
      goals: goals,
      insights: MockInsightsRepository(
        InsightRequestBuilder(journal: journal, goals: goals, assessment: assessment),
        latency: latency * 6,
      ),
      launchMood: LaunchMood(SharedPrefsLaunchExpressionStore()),
    );
  }

  /// On-device persistence: real SQLite storage, data survives restarts.
  /// Python isn't embedded yet, so the runtime is still the mock one.
  // TODO(backend): swap the runtime for SeriousPythonRuntime when it lands.
  // Keep these repositories if Flutter owns storage, otherwise replace them
  // with LocalApi*Repository (see api-contract.md "Storage").
  factory AppDependencies.sqflite({JourneyDatabase? database}) {
    final db = database ?? JourneyDatabase();
    final assessment = SqfliteAssessmentRepository(db);
    final journal = SqfliteJournalRepository(db);
    // TODO(backend): goals have no SQLite table yet, so they stay in memory.
    final goals = MockGoalRepository(MockPythonBackend(latency: Duration.zero));
    return AppDependencies(
      python: MockPythonRuntime(),
      assessment: assessment,
      journal: journal,
      prefs: SqflitePrefsRepository(db),
      premium: MockPremiumRepository(),
      goals: goals,
      insights: MockInsightsRepository(
        InsightRequestBuilder(journal: journal, goals: goals, assessment: assessment),
      ),
      launchMood: LaunchMood(SharedPrefsLaunchExpressionStore()),
    );
  }

  final PythonRuntime python;
  final AssessmentRepository assessment;
  final JournalRepository journal;
  final PrefsRepository prefs;
  final PremiumRepository premium;
  final GoalRepository goals;
  final InsightsRepository insights;

  /// Otter expression for the greeting box, chosen once per launch.
  final LaunchMood launchMood;
  final AppController app;
  final SessionState session = SessionState();
}

/// Makes [AppDependencies] available to the widget tree.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.deps, required super.child});

  final AppDependencies deps;

  /// Dependencies never change after startup, so this doesn't register a
  /// rebuild dependency. Listen to controllers for state changes instead.
  static AppDependencies of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found above this context');
    return scope!.deps;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => deps != oldWidget.deps;
}
