import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/models/goal.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/widgets/journey_card.dart';

/// Daily, weekly, and monthly goal lists. Each has an add button. Checking a
/// goal off deletes it.
class GoalsCard extends StatelessWidget {
  const GoalsCard({super.key, required this.goalsFor, required this.onAdd, required this.onComplete});

  /// Goals of a given period, in the order they were added.
  final List<Goal> Function(GoalPeriod period) goalsFor;

  /// Called with the period and the text the user typed.
  final Future<void> Function(GoalPeriod period, String text) onAdd;

  final void Function(Goal goal) onComplete;

  @override
  Widget build(BuildContext context) {
    return JourneyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, period) in GoalPeriod.values.indexed) ...[
            if (i > 0) const SizedBox(height: Space.md),
            _PeriodSection(
              period: period,
              goals: goalsFor(period),
              onAdd: onAdd,
              onComplete: onComplete,
            ),
          ],
        ],
      ),
    );
  }
}

class _PeriodSection extends StatelessWidget {
  const _PeriodSection({required this.period, required this.goals, required this.onAdd, required this.onComplete});

  final GoalPeriod period;
  final List<Goal> goals;
  final Future<void> Function(GoalPeriod period, String text) onAdd;
  final void Function(Goal goal) onComplete;

  Future<void> _add(BuildContext context) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _AddGoalDialog(period: period),
    );
    if (text != null) await onAdd(period, text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(period.title, style: context.tt.titleMedium),
              ),
            ),
            IconButton(
              tooltip: 'Add ${period.noun} goal',
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _add(context),
            ),
          ],
        ),
        if (goals.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: Space.xs, bottom: Space.xs),
            child: Text(
              'Nothing here yet.',
              style: context.tt.bodyMedium?.copyWith(color: context.jc.mutedText),
            ),
          )
        else
          for (final goal in goals)
            _GoalRow(goal: goal, onComplete: () => onComplete(goal)),
      ],
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal, required this.onComplete});

  final Goal goal;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: false,
          semanticLabel: 'Mark done: ${goal.text}',
          onChanged: (_) => onComplete(),
        ),
        const SizedBox(width: Space.xs),
        Expanded(child: Text(goal.text, style: context.tt.bodyLarge)),
      ],
    );
  }
}

class _AddGoalDialog extends StatefulWidget {
  const _AddGoalDialog({required this.period});

  final GoalPeriod period;

  @override
  State<_AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<_AddGoalDialog> {
  static const _maxLength = 80;

  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add ${widget.period.noun} goal'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: _maxLength,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(hintText: 'What do you want to do?'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
