import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../theme/spacing.dart';
import 'journey_card.dart';

/// Big tappable answer option (assessment answers, event choices).
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.usual = false,
    this.multiSelect = false,
    this.leadingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Marks the user's predicted default.
  final bool usual;
  final bool multiSelect;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final jc = context.jc;
    final radius = BorderRadius.circular(Radii.md);

    final indicator = multiSelect
        ? (selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded)
        : (selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded);

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: !multiSelect,
      label: usual ? '$label, usual' : label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: selected ? jc.primaryEdge.withValues(alpha: 0.5) : jc.cardEdge,
              offset: const Offset(0, Depth.card),
            ),
          ],
        ),
        child: Material(
          color: selected ? jc.selectedTint : cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: selected ? cs.primary : jc.cardBorder, width: 2),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
                child: Row(
                  children: [
                    Icon(leadingIcon ?? indicator, color: selected ? cs.primary : jc.mutedText),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Text(
                        label,
                        style: context.tt.bodyLarge?.copyWith(
                          color: selected ? cs.onPrimaryContainer : cs.onSurface,
                        ),
                      ),
                    ),
                    if (usual) const TagPill(label: 'usual', icon: Icons.history_rounded),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
