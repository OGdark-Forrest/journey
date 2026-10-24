import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/models/happiness.dart';
import '../theme/spacing.dart';
import 'chunky_button.dart';
import 'otter_mascot.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(dimension: 32, child: CircularProgressIndicator(strokeWidth: 3)),
          if (message != null) ...[
            const SizedBox(height: Space.lg),
            Text(message!, style: context.tt.bodyMedium?.copyWith(color: context.jc.mutedText)),
          ],
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OtterMascot(mood: Happiness.min + 1, size: 96),
            const SizedBox(height: Space.lg),
            Text(message, style: context.tt.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: Space.xl),
            ChunkyButton(label: 'Try again', icon: Icons.refresh_rounded, onPressed: onRetry, expand: false),
          ],
        ),
      ),
    );
  }
}
