import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/widgets/chunky_button.dart';
import '../../../shared/widgets/happiness_picker.dart';
import '../../../shared/widgets/option_tile.dart';
import '../../../shared/widgets/otter_mascot.dart';

typedef EventChoice = ({String value, bool custom});

/// Event picker: ~4 presets + a 5th "something else" free-text option.
Future<EventChoice?> showEventSheet(
  BuildContext context, {
  required List<String> options,
  required String usual,
  required String current,
  required bool currentIsCustom,
  required bool allowCustom,
  bool startWithCustom = false,
}) {
  return showModalBottomSheet<EventChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _EventSheet(
      options: options,
      usual: usual,
      current: current,
      currentIsCustom: currentIsCustom,
      allowCustom: allowCustom,
      startWithCustom: startWithCustom,
    ),
  );
}

class _EventSheet extends StatefulWidget {
  const _EventSheet({
    required this.options,
    required this.usual,
    required this.current,
    required this.currentIsCustom,
    required this.allowCustom,
    required this.startWithCustom,
  });

  final List<String> options;
  final String usual;
  final String current;
  final bool currentIsCustom;
  final bool allowCustom;
  final bool startWithCustom;

  @override
  State<_EventSheet> createState() => _EventSheetState();
}

class _EventSheetState extends State<_EventSheet> {
  late bool _customOpen = widget.startWithCustom || widget.currentIsCustom;
  late final _text = TextEditingController(text: widget.currentIsCustom ? widget.current : '');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submitCustom() {
    final v = _text.text.trim();
    if (v.isEmpty) return;
    Navigator.of(context).pop<EventChoice>((value: v, custom: true));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Keep the text field above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('What happened?', style: context.tt.titleLarge),
            const SizedBox(height: Space.lg),
            for (final o in widget.options) ...[
              OptionTile(
                label: o,
                usual: o == widget.usual,
                selected: !_customOpen && o == widget.current,
                onTap: () => Navigator.of(context).pop<EventChoice>((value: o, custom: false)),
              ),
              const SizedBox(height: Space.md),
            ],
            if (widget.allowCustom) ...[
              OptionTile(
                label: 'Something else',
                leadingIcon: Icons.edit_rounded,
                selected: _customOpen,
                onTap: () => setState(() => _customOpen = true),
              ),
              if (_customOpen) ...[
                const SizedBox(height: Space.md),
                TextField(
                  controller: _text,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(hintText: 'e.g. went to the dentist'),
                  onSubmitted: (_) => _submitCustom(),
                ),
                const SizedBox(height: Space.md),
                ListenableBuilder(
                  listenable: _text,
                  builder: (context, _) => ChunkyButton(
                    label: 'Use this',
                    onPressed: _text.text.trim().isEmpty ? null : _submitCustom,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Happiness picker in a sheet (used from the sentence chip, mainly in blitz).
Future<int?> showHappinessSheet(BuildContext context, {required int current, required int usual}) {
  return showModalBottomSheet<int>(
    context: context,
    useSafeArea: true,
    builder: (context) => _HappinessSheet(current: current, usual: usual),
  );
}

class _HappinessSheet extends StatefulWidget {
  const _HappinessSheet({required this.current, required this.usual});
  final int current;
  final int usual;

  @override
  State<_HappinessSheet> createState() => _HappinessSheetState();
}

class _HappinessSheetState extends State<_HappinessSheet> {
  late int _value = widget.current;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('How did it feel?', style: context.tt.titleLarge),
          const SizedBox(height: Space.md),
          Center(child: OtterMascot(mood: _value, size: 96)),
          const SizedBox(height: Space.md),
          HappinessPicker(value: _value, usual: widget.usual, onChanged: (v) => setState(() => _value = v)),
          const SizedBox(height: Space.lg),
          ChunkyButton(label: 'Done', onPressed: () => Navigator.of(context).pop(_value)),
        ],
      ),
    );
  }
}
