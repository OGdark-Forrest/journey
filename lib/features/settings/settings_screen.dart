import 'package:material_ui/material_ui.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../app/theme.dart';
import '../../core/models/time_slot.dart';
import '../../core/models/user_prefs.dart';
import '../../shared/theme/spacing.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/journey_card.dart';
import '../../shared/widgets/time_format.dart';
import '../../shared/widgets/time_slot_sheet.dart';

/// Small, local-only preferences.
// TODO(post-mvp): add an Account section (sign in / cloud sync) alongside the paywall.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AppController _app = AppScope.of(context).app;
  late final TextEditingController _name = TextEditingController(text: _app.prefs?.displayName ?? '');

  /// Live slider value; saved on release so we don't spam the backend.
  double? _entriesDraft;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _update(UserPrefs Function(UserPrefs p) change) async {
    final current = _app.prefs;
    if (current == null) return;
    try {
      await _app.updatePrefs(change(current));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Couldn\'t save that setting.')));
      }
    }
  }

  void _saveName() {
    final v = _name.text.trim();
    if (v.isNotEmpty && v != _app.prefs?.displayName) _update((p) => p.copyWith(displayName: v));
  }

  Future<void> _pickReminder(UserPrefs prefs) async {
    final slot = await showTimeSlotSheet(
      context,
      title: 'Remind me at',
      selected: prefs.reminderTime ?? const TimeSlot.hm(21, 0),
    );
    if (slot != null) _update((p) => p.copyWith(reminderTime: slot));
  }

  Future<void> _retakeAssessment() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retake the assessment?'),
        content: const Text('You\'ll answer the getting-to-know-you questions again. Your entries stay.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Retake')),
        ],
      ),
    );
    if (ok == true) _app.retakeAssessment(); // router redirects to onboarding
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, _) => _saveName(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListenableBuilder(
          listenable: _app,
          builder: (context, _) {
            final prefs = _app.prefs;
            if (prefs == null) return const SizedBox.shrink();
            final entries = (_entriesDraft ?? prefs.entriesPerDay.toDouble()).round();
            return ListView(
              padding: const EdgeInsets.fromLTRB(Space.screen, Space.sm, Space.screen, Space.xxl),
              children: [
                _Section(
                  title: 'You',
                  child: TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(labelText: 'Name'),
                    onSubmitted: (_) => _saveName(),
                    onTapOutside: (_) {
                      FocusScope.of(context).unfocus();
                      _saveName();
                    },
                  ),
                ),
                _Section(
                  title: 'Entries per day',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$entries a day', style: context.tt.headlineSmall),
                      Slider(
                        value: entries.toDouble(),
                        min: UserPrefs.minEntriesPerDay.toDouble(),
                        max: UserPrefs.maxEntriesPerDay.toDouble(),
                        divisions: UserPrefs.maxEntriesPerDay - UserPrefs.minEntriesPerDay,
                        label: '$entries',
                        semanticFormatterCallback: (v) => '${v.round()} entries a day',
                        onChanged: (v) => setState(() => _entriesDraft = v),
                        onChangeEnd: (v) async {
                          await _update((p) => p.copyWith(entriesPerDay: v.round()));
                          if (mounted) setState(() => _entriesDraft = null);
                        },
                      ),
                      Text(
                        'Each entry is one event. More entries help your journal understand your '
                        'day better, but take a bit more time.',
                        style: context.tt.bodyMedium?.copyWith(color: context.jc.mutedText),
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: 'Daily reminder',
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Remind me to journal'),
                        value: prefs.reminderTime != null,
                        onChanged: (on) => on
                            ? _update((p) => p.copyWith(reminderTime: const TimeSlot.hm(21, 0)))
                            : _update((p) => p.copyWith(clearReminder: true)),
                      ),
                      if (prefs.reminderTime != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Time'),
                          trailing: Text(
                            formatSlot(context, prefs.reminderTime!),
                            style: context.tt.titleMedium?.copyWith(color: context.cs.primary),
                          ),
                          onTap: () => _pickReminder(prefs),
                        ),
                      // TODO(post-mvp): actually schedule a local notification for this
                      // (e.g. flutter_local_notifications). Confirm whether reminders are MVP.
                    ],
                  ),
                ),
                _Section(
                  title: 'Appearance',
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemePreference>(
                      segments: const [
                        ButtonSegment(value: ThemePreference.system, label: Text('System')),
                        ButtonSegment(value: ThemePreference.light, label: Text('Light')),
                        ButtonSegment(value: ThemePreference.dark, label: Text('Dark')),
                      ],
                      selected: {prefs.theme},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => _update((p) => p.copyWith(theme: s.first)),
                    ),
                  ),
                ),
                _Section(
                  title: 'Getting to know you',
                  child: ChunkyButton(
                    label: 'Retake initial assessment',
                    icon: Icons.restart_alt_rounded,
                    variant: ChunkyVariant.secondary,
                    onPressed: _retakeAssessment,
                  ),
                ),
                const SizedBox(height: Space.lg),
                Center(
                  child: Text(
                    // TODO(backend): read the version from package_info / `GET /health`.
                    'Journey 0.1.0 · offline MVP',
                    style: context.tt.bodySmall?.copyWith(color: context.jc.mutedText),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: Space.xs, bottom: Space.sm),
            child: Semantics(
              header: true,
              child: Text(title, style: context.tt.titleSmall?.copyWith(color: context.jc.mutedText)),
            ),
          ),
          JourneyCard(child: child),
        ],
      ),
    );
  }
}
