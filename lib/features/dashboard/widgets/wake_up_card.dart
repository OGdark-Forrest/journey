import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/models/day_info.dart';
import '../../../core/models/time_slot.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/widgets/chunky_button.dart';
import '../../../shared/widgets/journey_card.dart';
import '../../../shared/widgets/time_format.dart';
import '../../../shared/widgets/time_slot_sheet.dart';

/// Once-a-day wake-up time. One tap confirms the usual time; collapses after.
class WakeUpCard extends StatelessWidget {
  const WakeUpCard({super.key, required this.day, required this.saving, required this.onSave});

  final DayInfo day;
  final bool saving;
  final ValueChanged<TimeSlot> onSave;

  Future<void> _change(BuildContext context) async {
    final slot = await showTimeSlotSheet(
      context,
      title: 'When did you wake up?',
      selected: day.wakeTime ?? day.wakeTimeDefault,
      usual: day.wakeTimeDefault,
      intervalMinutes: day.intervalMinutes,
    );
    if (slot != null) onSave(slot);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: day.wakeTimeAnswered ? _collapsed(context) : _prompt(context),
    );
  }

  Widget _prompt(BuildContext context) {
    final usual = formatSlot(context, day.wakeTimeDefault);
    return JourneyCard(
      color: context.jc.selectedTint,
      borderColor: context.cs.primary.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_twilight_rounded, color: context.jc.flame),
              const SizedBox(width: Space.sm),
              Expanded(child: Text('When did you wake up today?', style: context.tt.titleMedium)),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text('Your usual is $usual.', style: context.tt.bodyMedium?.copyWith(color: context.jc.mutedText)),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ChunkyButton(
                  label: 'Around $usual',
                  icon: Icons.check_rounded,
                  compact: true,
                  loading: saving,
                  onPressed: () => onSave(day.wakeTimeDefault),
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                flex: 2,
                child: ChunkyButton(
                  label: 'Change',
                  variant: ChunkyVariant.secondary,
                  compact: true,
                  onPressed: saving ? null : () => _change(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _collapsed(BuildContext context) {
    final time = formatSlot(context, day.wakeTime!);
    return JourneyCard(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.xs, Space.xs, Space.xs),
      child: Row(
        children: [
          Icon(Icons.wb_sunny_rounded, color: context.jc.flame, size: 22),
          const SizedBox(width: Space.sm),
          Expanded(child: Text('Woke up at $time', style: context.tt.bodyLarge)),
          TextButton(
            onPressed: saving ? null : () => _change(context),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
