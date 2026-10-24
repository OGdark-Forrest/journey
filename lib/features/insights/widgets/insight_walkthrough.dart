import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/widgets/chunky_button.dart';
import '../../../shared/widgets/journey_card.dart';

/// One page of an [InsightWalkthrough]: a section of the model's answer.
class WalkthroughStep {
  const WalkthroughStep({required this.title, required this.icon, required this.child});

  /// Short label under the progress bar, e.g. "Goal alignment".
  final String title;
  final IconData icon;

  /// Card content, header included. Scrolls if it's taller than the page.
  final Widget child;
}

/// Goes through an insight one section at a time: a segmented progress bar
/// (tap a segment to jump), the section card, and Back / Next buttons. The
/// last step's button calls [onFinished].
class InsightWalkthrough extends StatefulWidget {
  const InsightWalkthrough({
    super.key,
    required this.steps,
    required this.onFinished,
    this.finishLabel = 'See it all',
  });

  final List<WalkthroughStep> steps;
  final VoidCallback onFinished;
  final String finishLabel;

  @override
  State<InsightWalkthrough> createState() => _InsightWalkthroughState();
}

class _InsightWalkthroughState extends State<InsightWalkthrough> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool get _isLast => _index == widget.steps.length - 1;

  void _goTo(int i) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _pages.jumpToPage(i);
    } else {
      _pages.animateToPage(i, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.steps;
    final step = steps[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.screen),
          child: Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0) const SizedBox(width: Space.xs),
                Expanded(child: _Segment(filled: i <= _index, label: steps[i].title, onTap: () => _goTo(i))),
              ],
            ],
          ),
        ),
        const SizedBox(height: Space.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.screen),
          child: Semantics(
            liveRegion: true,
            child: Text(
              'Step ${_index + 1} of ${steps.length} · ${step.title}',
              style: context.tt.labelMedium?.copyWith(color: context.jc.mutedText),
            ),
          ),
        ),
        const SizedBox(height: Space.md),
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: steps.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, Space.lg),
              child: JourneyCard(child: steps[i].child),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.screen, Space.sm, Space.screen, Space.lg),
          child: Row(
            children: [
              Expanded(
                child: ChunkyButton(
                  label: 'Back',
                  icon: Icons.arrow_back_rounded,
                  variant: ChunkyVariant.secondary,
                  compact: true,
                  onPressed: _index == 0 ? null : () => _goTo(_index - 1),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                flex: 2,
                child: ChunkyButton(
                  label: _isLast ? widget.finishLabel : 'Next',
                  icon: _isLast ? Icons.view_agenda_rounded : Icons.arrow_forward_rounded,
                  compact: true,
                  onPressed: _isLast ? widget.onFinished : () => _goTo(_index + 1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.filled, required this.label, required this.onTap});

  final bool filled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Go to $label',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.pill),
        // Taller hit area than the bar itself.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.sm),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 8,
            decoration: BoxDecoration(
              color: filled ? context.cs.primary : context.jc.secondarySurface,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
        ),
      ),
    );
  }
}
