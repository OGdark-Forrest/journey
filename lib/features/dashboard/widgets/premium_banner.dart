import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../shared/theme/spacing.dart';

/// Compact, dismissible "get Premium" notice at the top of the dashboard.
class PremiumBanner extends StatelessWidget {
  const PremiumBanner({super.key, required this.onOpenInsights, required this.onDismiss});

  // TODO(post-mvp): real price from the paywall / store listing.
  static const priceLabel = '\$2.99/month';

  final VoidCallback onOpenInsights;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final jc = context.jc;
    final text = context.tt.bodyMedium?.copyWith(height: 1.3);
    final radius = BorderRadius.circular(Radii.md);

    return Container(
      decoration: BoxDecoration(
        color: jc.flameTint,
        borderRadius: radius,
        border: Border.all(color: jc.flame.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: 'Unlock Insights with Premium for $priceLabel. Open Insights',
              excludeSemantics: true,
              child: InkWell(
                onTap: onOpenInsights,
                borderRadius: radius,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, 0, Space.sm),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          style: text,
                          children: [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.only(right: Space.xs),
                                child: Icon(Icons.auto_awesome_rounded, size: 16, color: jc.flame),
                              ),
                            ),
                            const TextSpan(text: 'Unlock Insights with Premium for $priceLabel. '),
                            TextSpan(
                              text: 'click here',
                              style: text?.copyWith(
                                color: context.cs.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: context.cs.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Dismiss Premium banner',
            icon: const Icon(Icons.close_rounded, size: 18),
            color: jc.mutedText,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
