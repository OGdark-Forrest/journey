import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;

import '../core/models/user_prefs.dart';
import '../core/python/python_runtime.dart';
import '../core/repositories/repositories.dart';

enum BootStatus { booting, ready, failed }

/// App-wide state: Python backend readiness, onboarding status, and prefs.
/// The router listens to this to decide between splash / assessment / dashboard.
class AppController extends ChangeNotifier {
  AppController({
    required this._python,
    required this._assessment,
    required PrefsRepository prefs,
  }) : _prefsRepo = prefs {
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  final PythonRuntime _python;
  final AssessmentRepository _assessment;
  final PrefsRepository _prefsRepo;
  late final AppLifecycleListener _lifecycle;

  BootStatus _status = BootStatus.booting;
  BootStatus get status => _status;

  String? _bootError;
  String? get bootError => _bootError;

  bool _assessmentCompleted = false;
  bool get assessmentCompleted => _assessmentCompleted;

  UserPrefs? _prefs;
  UserPrefs? get prefs => _prefs;

  bool _booting = false;

  /// Fires only when something the router depends on changes (boot status or
  /// onboarding). Preference changes such as theme or name don't fire it:
  /// refreshing the router on those rebuilds the page stack and can leave
  /// pending `context.push` calls (and the dashboard's navigation guard) stuck.
  final ChangeNotifier _routingRefresh = ChangeNotifier();
  Listenable get routingRefresh => _routingRefresh;

  void _notifyRouting() {
    _routingRefresh.notifyListeners();
    notifyListeners();
  }

  ThemeMode get themeMode => switch (_prefs?.theme) {
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  /// Starts Python, waits for `/health`, then loads onboarding status + prefs.
  Future<void> boot() async {
    if (_booting) return;
    _booting = true;
    _status = BootStatus.booting;
    _bootError = null;
    _notifyRouting();
    try {
      await _python.start();
      final results = await Future.wait([_assessment.isCompleted(), _prefsRepo.fetch()]);
      _assessmentCompleted = results[0] as bool;
      _prefs = results[1] as UserPrefs;
      _status = BootStatus.ready;
    } catch (e) {
      debugPrint('Boot failed: $e');
      _bootError = 'We couldn\'t start your journal. Please try again.';
      _status = BootStatus.failed;
    } finally {
      _booting = false;
      _notifyRouting();
    }
  }

  /// Android may kill the Python process while the app is backgrounded.
  Future<void> _onResume() async {
    if (_status != BootStatus.ready) return;
    final healthy = await _python.checkHealth();
    // TODO(backend): with serious_python, restart Python here instead of a full
    // re-boot if only the server died. Mock runtime always reports healthy.
    if (!healthy) await boot();
  }

  Future<void> completeAssessment() async {
    _assessmentCompleted = true;
    // Assessment may have set the display name / usual wake time.
    _prefs = await _prefsRepo.fetch();
    _notifyRouting();
  }

  /// Sends the user back through onboarding (Settings -> Retake assessment).
  void retakeAssessment() {
    // TODO(backend): confirm with backend whether retaking should reset the
    // learned defaults or only update the answers.
    _assessmentCompleted = false;
    _notifyRouting();
  }

  Future<void> updatePrefs(UserPrefs next) async {
    final previous = _prefs;
    _prefs = next; // optimistic, so sliders/toggles feel instant
    notifyListeners();
    try {
      _prefs = await _prefsRepo.save(next);
    } catch (e) {
      _prefs = previous;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _routingRefresh.dispose();
    super.dispose();
  }
}
