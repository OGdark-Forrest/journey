import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/app_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO(backend): switch to the serious_python-backed dependencies once the
  // Python branch is merged (see AppDependencies.mock for details).
  runApp(JourneyApp(deps: AppDependencies.mock()));
}
