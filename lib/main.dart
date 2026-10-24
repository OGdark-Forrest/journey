import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/app_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO(backend): switch to the serious_python-backed dependencies once the
  // Python branch is merged (see AppDependencies.mock for details).
  final deps = AppDependencies.mock();
  // Pick this launch's otter face before the first frame (never throws,
  // times out after 2s).
  await deps.launchMood.init();
  runApp(JourneyApp(deps: deps));
}
