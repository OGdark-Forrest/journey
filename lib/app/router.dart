import 'package:go_router/go_router.dart';

import '../core/models/entry.dart';
import '../features/assessment/assessment_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/log_entry/log_entry_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import 'app_controller.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const assessment = '/assessment';
  static const dashboard = '/';
  static const logEntry = '/log';
  static const settings = '/settings';
  static const insights = '/insights';

  static String logEntryFor(EntryMode mode) => '$logEntry?mode=${mode.apiName}';
}

/// First launch: splash -> assessment -> dashboard. Afterwards: splash -> dashboard.
GoRouter buildRouter(AppController app) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: app,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (app.status != BootStatus.ready) {
        return loc == Routes.splash ? null : Routes.splash;
      }
      if (!app.assessmentCompleted) {
        return loc == Routes.assessment ? null : Routes.assessment;
      }
      if (loc == Routes.splash || loc == Routes.assessment) return Routes.dashboard;
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.assessment, builder: (_, _) => const AssessmentScreen()),
      GoRoute(
        path: Routes.dashboard,
        builder: (_, _) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: 'log',
            builder: (_, state) => LogEntryScreen(
              initialMode: EntryMode.fromApi(state.uri.queryParameters['mode']),
            ),
          ),
          GoRoute(path: 'settings', builder: (_, _) => const SettingsScreen()),
          GoRoute(path: 'insights', builder: (_, _) => const InsightsScreen()),
        ],
      ),
    ],
  );
}
