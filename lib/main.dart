import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/app_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
    final deps = _createDependencies();
  // Pick this launch's otter face before the first frame (never throws,
  // times out after 2s).
  await deps.launchMood.init();
  runApp(JourneyApp(deps: deps));
}

/// Real on-device storage where sqflite runs natively (Android, iOS, macOS).
/// Web, Windows and Linux fall back to the in-memory mock so teammates can
/// still run the UI there; nothing is saved on those platforms.
// TODO(backend): switch to the serious_python-backed dependencies once the
// Python branch is merged (see AppDependencies.mock for details).
AppDependencies _createDependencies() {
  final hasNativeSqlite = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
  return hasNativeSqlite ? AppDependencies.sqflite() : AppDependencies.mock();
}
