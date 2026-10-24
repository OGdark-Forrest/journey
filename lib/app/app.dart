import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'app_scope.dart';
import 'router.dart';
import 'theme.dart';

class JourneyApp extends StatefulWidget {
  const JourneyApp({super.key, required this.deps});

  final AppDependencies deps;

  @override
  State<JourneyApp> createState() => _JourneyAppState();
}

class _JourneyAppState extends State<JourneyApp> {
  late final GoRouter _router = buildRouter(widget.deps.app);
  final _light = JourneyTheme.light();
  final _dark = JourneyTheme.dark();

  @override
  void dispose() {
    _router.dispose();
    widget.deps.app.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      deps: widget.deps,
      child: ListenableBuilder(
        listenable: widget.deps.app,
        builder: (context, _) => MaterialApp.router(
          title: 'Journey',
          debugShowCheckedModeBanner: false,
          theme: _light,
          darkTheme: _dark,
          themeMode: widget.deps.app.themeMode,
          routerConfig: _router,
        ),
      ),
    );
  }
}
