import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../theme/palette.dart';
import '../theme/spacing.dart';

enum ChunkyVariant { primary, secondary, flame, earth }

/// Duolingo-style button with a solid bottom edge that "presses in" on tap.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = ChunkyVariant.primary,
    this.expand = true,
    this.loading = false,
    this.compact = false,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final IconData? icon;
  final ChunkyVariant variant;

  /// Stretch to the available width.
  final bool expand;
  final bool loading;
  final bool compact;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final jc = context.jc;

    final (face, edge, fg, border) = switch (widget.variant) {
      _ when !_enabled && !widget.loading => (
          jc.secondarySurface,
          jc.cardEdge,
          jc.mutedText,
          null,
        ),
      ChunkyVariant.primary => (cs.primary, jc.primaryEdge, cs.onPrimary, null),
      ChunkyVariant.flame => (cs.tertiary, jc.flame.withValues(alpha: 0.6), cs.onTertiary, null),
      ChunkyVariant.secondary => (cs.surface, jc.cardEdge, cs.onSurface, jc.cardBorder),
      // White face on the earth gradient; text in the cocoa brown used across the app.
      ChunkyVariant.earth => (Colors.white, Palette.earthEdge, Palette.cocoa, null),
    };
    // Darker flame edge reads better than the translucent fallback above.
    final edgeColor = widget.variant == ChunkyVariant.flame && _enabled
        ? Color.alphaBlend(Colors.black.withValues(alpha: 0.18), cs.tertiary)
        : edge;

    final depth = _pressed ? 0.0 : Depth.button;
    final vPad = widget.compact ? Space.md : Space.lg;

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
          )
        else if (widget.icon != null)
          Icon(widget.icon, color: fg, size: 22),
        if (widget.loading || widget.icon != null) const SizedBox(width: Space.sm),
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: context.tt.labelLarge?.copyWith(color: fg, fontSize: widget.compact ? 15 : 17),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.loading ? '${widget.label}, loading' : widget.label,
      excludeSemantics: true,
      onTap: _enabled ? _handleTap : null,
      child: GestureDetector(
        excludeFromSemantics: true,
        onTapDown: _enabled ? (_) => _setPressed(true) : null,
        onTapUp: _enabled ? (_) => _setPressed(false) : null,
        onTapCancel: () => _setPressed(false),
        onTap: _enabled ? _handleTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            margin: EdgeInsets.only(top: Depth.button - depth),
            padding: EdgeInsets.only(bottom: depth),
            decoration: BoxDecoration(
              color: edgeColor,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: Space.lg, vertical: vPad),
              decoration: BoxDecoration(
                color: face,
                borderRadius: BorderRadius.circular(Radii.md),
                border: border == null ? null : Border.all(color: border, width: 2),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onPressed?.call();
  }
}
