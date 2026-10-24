import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/models/happiness.dart';
import '../theme/spacing.dart';
import 'otter_mascot.dart';

/// Row of 5 otter faces for the 1-5 happiness scale.
class HappinessPicker extends StatelessWidget {
  const HappinessPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.usual,
    this.min = Happiness.min,
    this.max = Happiness.max,
  });

  final int value;
  final ValueChanged<int> onChanged;

  /// The predicted default, marked with a small dot.
  final int? usual;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var v = min; v <= max; v++)
          Expanded(child: _Face(level: v, selected: v == value, usual: v == usual, onTap: () => onChanged(v))),
      ],
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.level, required this.selected, required this.usual, required this.onTap});

  final int level;
  final bool selected;
  final bool usual;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final jc = context.jc;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '${Happiness.label(level)}, $level of ${Happiness.max}${usual ? ', usual' : ''}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? jc.selectedTint : Colors.transparent,
                  border: Border.all(color: selected ? cs.primary : Colors.transparent, width: 2.5),
                ),
                child: AnimatedScale(
                  scale: selected ? 1.08 : 0.92,
                  duration: const Duration(milliseconds: 180),
                  child: OtterMascot(mood: level, size: 46, animate: false),
                ),
              ),
              const SizedBox(height: Space.xs),
              Text(
                Happiness.label(level),
                style: context.tt.labelSmall?.copyWith(
                  color: selected ? cs.primary : jc.mutedText,
                ),
              ),
              SizedBox(
                height: 8,
                child: usual
                    ? Center(
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(color: jc.mutedText, shape: BoxShape.circle),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
