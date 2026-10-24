import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../theme/spacing.dart';

/// Rounded-rectangle card with a soft solid bottom edge.
class JourneyCard extends StatelessWidget {
  const JourneyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.lg),
    this.onTap,
    this.color,
    this.borderColor,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final jc = context.jc;
    final radius = BorderRadius.circular(Radii.lg);

    Widget body = Padding(padding: padding, child: child);
    if (onTap != null) {
      body = InkWell(onTap: onTap, borderRadius: radius, child: body);
    }

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [BoxShadow(color: jc.cardEdge, offset: const Offset(0, Depth.card))],
        ),
        child: Material(
          color: color ?? context.cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: borderColor ?? jc.cardBorder, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: body,
        ),
      ),
    );
  }
}

/// Small rounded label, e.g. "usual" or "edited".
class TagPill extends StatelessWidget {
  const TagPill({super.key, required this.label, this.icon, this.background, this.foreground});

  final String label;
  final IconData? icon;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? context.jc.mutedText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 2),
      decoration: BoxDecoration(
        color: background ?? context.jc.secondarySurface,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 3)],
          Text(label, style: context.tt.labelSmall?.copyWith(color: fg)),
        ],
      ),
    );
  }
}
