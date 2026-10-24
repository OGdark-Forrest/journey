import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/models/happiness.dart';
import '../theme/palette.dart';
import '../theme/spacing.dart';
import 'chunky_button.dart';
import 'otter_mascot.dart';

/// Full-screen celebration with a confetti burst. Reserve for meaningful
/// moments (finishing onboarding, keeping the streak, hitting the daily goal)
/// so it stays special.
Future<void> showCelebration(
  BuildContext context, {
  required String title,
  String? message,
  String buttonLabel = 'Continue',
  Widget? highlight,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 260),
    transitionBuilder: (context, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
        child: child,
      ),
    ),
    pageBuilder: (context, _, _) => _Celebration(
      title: title,
      message: message,
      buttonLabel: buttonLabel,
      highlight: highlight,
    ),
  );
}

class _Celebration extends StatefulWidget {
  const _Celebration({required this.title, required this.message, required this.buttonLabel, this.highlight});

  final String title;
  final String? message;
  final String buttonLabel;
  final Widget? highlight;

  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration> {
  final _confetti = ConfettiController(duration: const Duration(milliseconds: 900));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!_started && !reduceMotion) {
      _started = true;
      _confetti.play();
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Material(
              color: context.cs.surface,
              borderRadius: BorderRadius.circular(Radii.xl),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.xl, Space.xl, Space.xl, Space.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const OtterMascot(mood: Happiness.max, size: 120),
                    const SizedBox(height: Space.md),
                    Text(widget.title, style: context.tt.headlineSmall, textAlign: TextAlign.center),
                    if (widget.message != null) ...[
                      const SizedBox(height: Space.sm),
                      Text(
                        widget.message!,
                        style: context.tt.bodyLarge?.copyWith(color: context.jc.mutedText),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (widget.highlight != null) ...[
                      const SizedBox(height: Space.lg),
                      widget.highlight!,
                    ],
                    const SizedBox(height: Space.xl),
                    ChunkyButton(
                      label: widget.buttonLabel,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            blastDirection: math.pi / 2,
            emissionFrequency: 0.08,
            numberOfParticles: 14,
            gravity: 0.25,
            maxBlastForce: 22,
            minBlastForce: 8,
            colors: Palette.confetti,
          ),
        ),
      ],
    );
  }
}
