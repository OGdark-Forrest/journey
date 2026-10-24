import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/models/insight.dart';
import '../../../shared/theme/spacing.dart';

/// Renders a section's lines: paragraphs, bullet lists, and small headings.
/// `**bold**` spans from the model are kept.
class InsightText extends StatelessWidget {
  const InsightText(this.lines, {super.key});

  final List<InsightLine> lines;

  @override
  Widget build(BuildContext context) {
    final body = context.tt.bodyLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, line) in lines.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : (line.subheading ? Space.lg : Space.sm)),
            child: switch (line) {
              InsightLine(subheading: true) => Semantics(
                  header: true,
                  child: Text(Insight.stripBold(line.text), style: context.tt.titleSmall),
                ),
              InsightLine(bullet: true) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 9, right: Space.md),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: context.cs.primary, shape: BoxShape.circle),
                      ),
                    ),
                    Expanded(child: RichText(text: boldSpans(context, line.text, body))),
                  ],
                ),
              _ => RichText(text: boldSpans(context, line.text, body)),
            },
          ),
      ],
    );
  }
}

/// Splits `**bold**` markers into styled spans.
TextSpan boldSpans(BuildContext context, String text, TextStyle? style) {
  final bold = style?.copyWith(fontWeight: FontWeight.w800, fontVariations: const [FontVariation('wght', 800)]);
  final parts = text.split('**');
  return TextSpan(
    style: style,
    children: [
      // Odd indexes were between ** pairs. An unmatched ** just shows plain.
      for (final (i, part) in parts.indexed)
        if (part.isNotEmpty) TextSpan(text: part, style: i.isOdd && i < parts.length - 1 ? bold : null),
    ],
  );
}

/// Round icon badge used in section headers.
class SectionBadge extends StatelessWidget {
  const SectionBadge({super.key, required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.cs.primary;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.16), shape: BoxShape.circle),
      child: Icon(icon, color: c, size: 22),
    );
  }
}

/// Icon + title row at the top of a section card.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.icon, required this.title, this.color});

  final IconData icon;
  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SectionBadge(icon: icon, color: color),
        const SizedBox(width: Space.md),
        Expanded(child: Semantics(header: true, child: Text(title, style: context.tt.titleLarge))),
      ],
    );
  }
}

/// [SectionHeader] above a section's content.
class SectionContent extends StatelessWidget {
  const SectionContent({super.key, required this.icon, required this.title, required this.child, this.color});

  final IconData icon;
  final String title;
  final Color? color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(icon: icon, title: title, color: color),
        const SizedBox(height: Space.lg),
        child,
      ],
    );
  }
}
