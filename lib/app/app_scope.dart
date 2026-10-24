import 'package:flutter/widgets.dart';

import '../core/python/python_runtime.dart';
import '../core/repositories/mock/mock_python_backend.dart';
import '../core/repositories/mock/mock_repositories.dart';
import '../core/repositories/repositories.dart';
import '../core/storage/launch_mood.dart';
import 'app_controller.dart';

/// Per-launch UI state that must outlive a single screen (screens can be
/// rebuilt, e.g. after retaking the assessment). Resets on app restart.
class SessionState {
  /// The user closed the Premium banner during this launch.
  bool premiumBannerDismissed = false;
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
    required this.launchMood,
  }) : app = AppController(python: python, assessment: assessment, prefs: prefs);

  /// MVP wiring: fake Python runtime + in-memory mock backend.
  // TODO(backend): add `AppDependencies.local()` that builds a
  // SeriousPythonRuntime and LocalApi*Repository instances sharing its
  // baseUrl/token, and use it in main.dart.
  factory AppDependencies.mock({Duration latency = const Duration(milliseconds: 250)}) {
    final backend = MockPythonBackend(latency: latency);
    return AppDependencies(
      python: MockPythonRuntime(),
      assessment: MockAssessmentRepository(backend),
      journal: MockJournalRepository(backend),
      prefs: MockPrefsRepository(backend),
      premium: MockPremiumRepository(),
      goals: MockGoalRepository(backend),
      launchMood: LaunchMood(SharedPrefsLaunchExpressionStore()),
    );
  }

  final PythonRuntime python;
  final AssessmentRepository assessment;
  final JournalRepository journal;
  final PrefsRepository prefs;
  final PremiumRepository premium;
  final GoalRepository goals;

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
