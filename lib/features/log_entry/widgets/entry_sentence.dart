import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../shared/theme/spacing.dart';

/// One tappable value inside the sentence.
class SentenceChip {
  const SentenceChip({
    required this.label,
    required this.fieldName,
    required this.isDefault,
    required this.onTap,
  });

  final String label;

  /// For screen readers, e.g. "Time".
  final String fieldName;
  final bool isDefault;
  final VoidCallback onTap;
}

/// Renders a draft template like "At {time}, I {event} and felt {happiness}."
/// with each `{token}` as an inline chip. Unknown tokens are shown as-is.
class EntrySentence extends StatelessWidget {
  const EntrySentence({super.key, required this.template, required this.chips});

  final String template;
  final Map<String, SentenceChip> chips;

  static final _token = RegExp(r'\{(\w+)\}');

  @override
  Widget build(BuildContext context) {
    final style = context.tt.bodyLarge?.copyWith(fontSize: 21, height: 1.9);
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in _token.allMatches(template)) {
      if (m.start > cursor) spans.add(TextSpan(text: template.substring(cursor, m.start)));
      final chip = chips[m.group(1)];
      spans.add(
        chip == null
            ? TextSpan(text: m.group(0))
            : WidgetSpan(alignment: PlaceholderAlignment.middle, child: _InlineChip(chip: chip)),
      );
      cursor = m.end;
    }
    if (cursor < template.length) spans.add(TextSpan(text: template.substring(cursor)));

    return Text.rich(TextSpan(style: style, children: spans));
  }
}

class _InlineChip extends StatelessWidget {
  const _InlineChip({required this.chip});
  final SentenceChip chip;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final jc = context.jc;
    final edited = !chip.isDefault;
    final fg = edited ? cs.onPrimary : cs.onPrimaryContainer;

    return Semantics(
      button: true,
      label: '${chip.fieldName}: ${chip.label}, ${edited ? 'edited' : 'usual'}. Tap to change.',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Material(
          color: edited ? cs.primary : jc.selectedTint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
            side: BorderSide(color: cs.primary.withValues(alpha: edited ? 1 : 0.45), width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.sm),
            onTap: () {
              HapticFeedback.selectionClick();
              chip.onTap();
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.sm + 2, vertical: Space.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        chip.label,
                        style: context.tt.titleMedium?.copyWith(color: fg, fontSize: 19, height: 1.2),
                      ),
                    ),
                    const SizedBox(width: Space.xs),
                    Icon(edited ? Icons.edit_rounded : Icons.expand_more_rounded, size: 16, color: fg),
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
