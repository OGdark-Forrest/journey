import 'package:material_ui/material_ui.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../app/theme.dart';
import '../../core/models/happiness.dart';
import '../../shared/theme/spacing.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/otter_mascot.dart';

/// Starts the (mock) Python backend and waits for it. The router moves on
/// automatically once [AppController.status] is ready.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AppController _app = AppScope.of(context).app;

  @override
  void initState() {
    super.initState();
    // Kick off after the first frame so the splash is visible immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_app.status != BootStatus.ready) _app.boot();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _app,
          builder: (context, _) {
            final failed = _app.status == BootStatus.failed;
            return Padding(
              padding: const EdgeInsets.all(Space.xl),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  OtterMascot(mood: failed ? Happiness.min + 1 : Happiness.max - 1, size: 150),
                  const SizedBox(height: Space.lg),
                  Text('Journey', style: context.tt.displaySmall),
                  const SizedBox(height: Space.sm),
                  Text(
                    failed ? _app.bootError ?? 'Something went wrong.' : 'Opening your journal…',
                    textAlign: TextAlign.center,
                    style: context.tt.bodyLarge?.copyWith(color: context.jc.mutedText),
                  ),
                  const Spacer(flex: 2),
                  if (failed)
                    ChunkyButton(label: 'Try again', icon: Icons.refresh_rounded, onPressed: _app.boot)
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.pill),
                      child: const SizedBox(
                        width: 160,
                        child: LinearProgressIndicator(minHeight: 8, semanticsLabel: 'Loading'),
                      ),
                    ),
                  const Spacer(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
