import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../shared/theme/palette.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/widgets/chunky_button.dart';

/// "Enter your log" card on a light green-brown gradient. Holds the button
/// that starts a new entry. No daily limit: the button is always enabled.
class LogCard extends StatelessWidget {
  const LogCard({super.key, required this.onLogEvent});

  final VoidCallback onLogEvent;

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Palette.earthGreen, Palette.earthBrown],
  );

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Radii.lg);
    return DecoratedBox(
      // Same 3D bottom edge as the other cards.
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [BoxShadow(color: Palette.earthEdge, offset: Offset(0, Depth.card))],
      ),
      child: Container(
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(gradient: _gradient, borderRadius: radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Enter your log',
                style: context.tt.titleMedium?.copyWith(color: Palette.cocoa),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: Space.md),
            ChunkyButton(
              label: 'Log an event',
              icon: Icons.add_rounded,
              variant: ChunkyVariant.earth,
              onPressed: onLogEvent,
            ),
          ],
        ),
      ),
    );
  }
}
