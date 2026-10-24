import 'package:flutter/widgets.dart';

import '../core/python/python_runtime.dart';
import '../core/repositories/mock/mock_python_backend.dart';
import '../core/repositories/local/journey_database.dart';
import '../core/repositories/local/sqflite_repositories.dart';
import '../core/repositories/mock/mock_repositories.dart';
import '../core/repositories/repositories.dart';
import 'app_controller.dart';

/// Everything screens need, created once at startup.
class AppDependencies {
  AppDependencies({
    required this.python,
    required this.assessment,
    required this.journal,
    required this.prefs,
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
    );
  }

  /// On-device persistence: real SQLite storage, data survives restarts.
  /// Python isn't embedded yet, so the runtime is still the mock one.
  // TODO(backend): swap the runtime for SeriousPythonRuntime when it lands.
  // Keep these repositories if Flutter owns storage, otherwise replace them
  // with LocalApi*Repository (see api-contract.md "Storage").
  factory AppDependencies.sqflite({JourneyDatabase? database}) {
    final db = database ?? JourneyDatabase();
    return AppDependencies(
      python: MockPythonRuntime(),
      assessment: SqfliteAssessmentRepository(db),
      journal: SqfliteJournalRepository(db),
      prefs: SqflitePrefsRepository(db),
    );
  }

  final PythonRuntime python;
  final AssessmentRepository assessment;
  final JournalRepository journal;
  final PrefsRepository prefs;
  final AppController app;
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
