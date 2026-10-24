import 'package:go_router/go_router.dart';

import '../features/assessment/assessment_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/insights/recommendations_screen.dart';
import '../features/insights/reflection_screen.dart';
import '../features/log_entry/log_entry_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/streak/weekly_streak_screen.dart';
import 'app_controller.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const assessment = '/assessment';
  static const dashboard = '/';
  static const logEntry = '/log';
  static const settings = '/settings';
  static const insights = '/insights';
  static const reflection = '/insights/reflection';
  static const recommendations = '/insights/recommendations';
  static const weeklyStreak = '/streak';

}

/// First launch: splash -> assessment -> dashboard. Afterwards: splash -> dashboard.
GoRouter buildRouter(AppController app) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: app.routingRefresh,
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
            builder: (_, _) => const LogEntryScreen(),
          ),
          GoRoute(path: 'settings', builder: (_, _) => const SettingsScreen()),
          GoRoute(
            path: 'insights',
            builder: (_, _) => const InsightsScreen(),
            routes: [
              GoRoute(path: 'reflection', builder: (_, _) => const ReflectionScreen()),
              GoRoute(path: 'recommendations', builder: (_, _) => const RecommendationsScreen()),
            ],
          ),
          GoRoute(path: 'streak', builder: (_, _) => const WeeklyStreakScreen()),
        ],
      ),
    ],
  );
}
