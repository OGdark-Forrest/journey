import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../app/theme.dart';
import '../../core/models/entry.dart';
import '../../core/models/happiness.dart';
import '../../shared/theme/spacing.dart';
import '../../shared/widgets/celebration.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/happiness_picker.dart';
import '../../shared/widgets/journey_card.dart';
import '../../shared/widgets/option_tile.dart';
import '../../shared/widgets/otter_mascot.dart';
import '../../shared/widgets/state_views.dart';
import '../../shared/widgets/streak_pill.dart';
import '../../shared/widgets/time_format.dart';
import '../../shared/widgets/time_slot_sheet.dart';
import 'log_entry_controller.dart';
import 'widgets/entry_sentence.dart';
import 'widgets/field_sheets.dart';

/// The core screen: a prewritten entry (one event, 3 fields) the user tweaks.
/// Pops with the [SaveEntryResult] after saving.
class LogEntryScreen extends StatefulWidget {
  const LogEntryScreen({super.key, required this.initialMode});

  final EntryMode initialMode;

  @override
  State<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  late final LogEntryController _c = LogEntryController(
    AppScope.of(context).journal,
    mode: widget.initialMode,
  );

  @override
  void initState() {
    super.initState();
    _c.load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // ---- Field editors -------------------------------------------------------

  Future<void> _editTime() async {
    final d = _c.draft!;
    final slot = await showTimeSlotSheet(
      context,
      title: 'When did it happen?',
      selected: _c.time,
      usual: d.timeDefault,
      intervalMinutes: d.intervalMinutes,
    );
    if (slot != null) _c.setTime(slot);
  }

  Future<void> _editHappiness() async {
    final v = await showHappinessSheet(context, current: _c.happiness, usual: _c.draft!.happinessDefault);
    if (v != null) _c.setHappiness(v);
  }

  Future<void> _editEvent({bool startWithCustom = false}) async {
    final d = _c.draft!;
    final choice = await showEventSheet(
      context,
      options: d.eventOptions,
      usual: d.eventDefault,
      current: _c.event,
      currentIsCustom: _c.eventCustom,
      allowCustom: d.allowCustom,
      startWithCustom: startWithCustom,
    );
    if (choice != null) _c.setEvent(choice.value, custom: choice.custom);
  }

  // ---- Save ----------------------------------------------------------------

  Future<void> _save() async {
    final result = await _c.save();
    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_c.error ?? 'Couldn\'t save.')));
      return;
    }
    if (shouldCelebrate(result)) {
      final goal = result.indexToday == result.streak.entriesPerDay;
      await showCelebration(
        context,
        title: goal ? 'Daily goal done!' : 'Streak kept!',
        message: goal
            ? 'All ${result.streak.entriesPerDay} entries logged today.'
            : 'First entry of the day is in. See you for the next one.',
        highlight: StreakPill(days: result.streak.current, activeToday: true),
      );
      if (!mounted) return;
    }
    context.pop(result);
  }

  // ---- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final d = _c.draft;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context.pop(),
            ),
            title: Text(d == null ? 'New entry' : 'Entry ${d.indexToday} of ${d.entriesPerDay}'),
          ),
          body: _body(context),
          bottomNavigationBar: d == null || _c.loading
              ? null
              : SafeArea(
                  minimum: const EdgeInsets.fromLTRB(Space.screen, Space.sm, Space.screen, Space.lg),
                  child: ChunkyButton(
                    label: _c.mode == EntryMode.blitz ? 'Looks right, save' : 'Save entry',
                    icon: Icons.check_rounded,
                    loading: _c.saving,
                    onPressed: _c.canSave ? _save : null,
                  ),
                ),
        );
      },
    );
  }

  Widget _body(BuildContext context) {
    if (_c.loading) return const LoadingView(message: 'Writing your entry…');
    final d = _c.draft;
    if (d == null) return ErrorView(message: _c.error ?? 'Something went wrong.', onRetry: _c.load);

    final blitz = _c.mode == EntryMode.blitz;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.screen, Space.sm, Space.screen, Space.xl),
      children: [
        SegmentedButton<EntryMode>(
          segments: const [
            ButtonSegment(value: EntryMode.normal, label: Text('Normal'), icon: Icon(Icons.edit_note_rounded)),
            ButtonSegment(value: EntryMode.blitz, label: Text('Blitz'), icon: Icon(Icons.bolt_rounded)),
          ],
          selected: {_c.mode},
          showSelectedIcon: false,
          onSelectionChanged: (s) => _c.setMode(s.first),
        ),
        const SizedBox(height: Space.xl),
        _OtterSays(
          mood: _c.happiness,
          size: blitz ? 80 : 104,
          text: blitz
              ? 'Quick one? Here\'s my best guess. Tap anything that\'s off.'
              : 'Here\'s what I think happened. Keep what\'s right, change what isn\'t.',
        ),
        const SizedBox(height: Space.lg),
        JourneyCard(
          padding: const EdgeInsets.all(Space.xl),
          child: EntrySentence(
            template: d.template,
            chips: {
              'time': SentenceChip(
                label: formatSlot(context, _c.time),
                fieldName: 'Time',
                isDefault: _c.timeIsDefault,
                onTap: _editTime,
              ),
              'event': SentenceChip(
                label: _c.event,
                fieldName: 'Event',
                isDefault: _c.eventIsDefault,
                onTap: _editEvent,
              ),
              'happiness': SentenceChip(
                label: Happiness.phrase(_c.happiness),
                fieldName: 'Feeling',
                isDefault: _c.happinessIsDefault,
                onTap: _editHappiness,
              ),
            },
          ),
        ),
        if (!blitz) ...[
          const SizedBox(height: Space.xl),
          _FieldCard(
            title: 'How did it feel?',
            icon: Icons.sentiment_satisfied_rounded,
            isDefault: _c.happinessIsDefault,
            onReset: _c.resetHappiness,
            child: HappinessPicker(
              value: _c.happiness,
              usual: d.happinessDefault,
              onChanged: _c.setHappiness,
            ),
          ),
          const SizedBox(height: Space.lg),
          _FieldCard(
            title: 'What happened?',
            icon: Icons.local_activity_rounded,
            isDefault: _c.eventIsDefault,
            onReset: _c.resetEvent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final o in d.eventOptions) ...[
                  OptionTile(
                    label: o,
                    usual: o == d.eventDefault,
                    selected: !_c.eventCustom && _c.event == o,
                    onTap: () => _c.setEvent(o),
                  ),
                  const SizedBox(height: Space.sm),
                ],
                if (d.allowCustom)
                  OptionTile(
                    label: _c.eventCustom ? _c.event : 'Something else',
                    leadingIcon: Icons.edit_rounded,
                    selected: _c.eventCustom,
                    onTap: () => _editEvent(startWithCustom: true),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          _FieldCard(
            title: 'When?',
            icon: Icons.schedule_rounded,
            isDefault: _c.timeIsDefault,
            onReset: _c.resetTime,
            child: Row(
              children: [
                Expanded(child: Text(formatSlot(context, _c.time), style: context.tt.headlineSmall)),
                ChunkyButton(
                  label: 'Change',
                  variant: ChunkyVariant.secondary,
                  compact: true,
                  expand: false,
                  onPressed: _editTime,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _OtterSays extends StatelessWidget {
  const _OtterSays({required this.mood, required this.text, required this.size});
  final int mood;
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: OtterMascot(mood: mood, size: size),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: Text(text, style: context.tt.bodyLarge?.copyWith(color: context.jc.mutedText)),
        ),
      ],
    );
  }
}

/// Card for one of the 3 fields, with a "usual" tag or a reset action.
class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.title,
    required this.icon,
    required this.isDefault,
    required this.onReset,
    required this.child,
  });

  final String title;
  final IconData icon;
  final bool isDefault;
  final VoidCallback onReset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return JourneyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: context.cs.primary, size: 22),
              const SizedBox(width: Space.sm),
              Expanded(child: Text(title, style: context.tt.titleMedium)),
              SizedBox(
                height: 36,
                child: isDefault
                    ? const Center(child: TagPill(label: 'usual', icon: Icons.history_rounded))
                    : TextButton.icon(
                        onPressed: onReset,
                        icon: const Icon(Icons.undo_rounded, size: 18),
                        label: const Text('Use usual'),
                      ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          child,
        ],
      ),
    );
  }
}
