import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../app/theme.dart';
import '../../core/models/assessment.dart';
import '../../core/models/happiness.dart';
import '../../core/models/time_slot.dart';
import '../../shared/theme/spacing.dart';
import '../../shared/widgets/celebration.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/option_tile.dart';
import '../../shared/widgets/otter_mascot.dart';
import '../../shared/widgets/state_views.dart';
import '../../shared/widgets/time_format.dart';
import '../../shared/widgets/time_slot_sheet.dart';
import 'assessment_controller.dart';

/// First-launch onboarding: an intro, then one question per page.
class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  late final AssessmentController _c = AssessmentController(AppScope.of(context).assessment);
  bool _showIntro = true;

  /// Per-question text controllers (name, custom answers).
  final Map<String, TextEditingController> _text = {};

  /// Questions where the user opened "Something else".
  final Set<String> _customOpen = {};

  @override
  void initState() {
    super.initState();
    _c.load();
  }

  @override
  void dispose() {
    _c.dispose();
    for (final t in _text.values) {
      t.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String id) => _text.putIfAbsent(id, TextEditingController.new);

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    final app = AppScope.of(context).app;
    if (!_c.isLast) {
      _c.next();
      return;
    }
    final ok = await _c.submit();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_c.error ?? 'Something went wrong.')));
      return;
    }
    await showCelebration(
      context,
      title: 'You\'re all set!',
      message: 'Your entries will come mostly prewritten from now on. Just tweak what was different.',
      buttonLabel: 'Go to my journal',
    );
    // Router redirects to the dashboard once this flips.
    await app.completeAssessment();
  }

  void _back() {
    if (!_c.back()) setState(() => _showIntro = true);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        return PopScope(
          // Android back steps through questions instead of leaving onboarding.
          canPop: _showIntro,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _back();
          },
          child: Scaffold(
            body: SafeArea(child: _body(context)),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context) {
    if (_showIntro) return _Intro(onStart: () => setState(() => _showIntro = false));
    if (_c.loading) return const LoadingView();
    if (_c.error != null && _c.questions.isEmpty) return ErrorView(message: _c.error!, onRetry: _c.load);
    final q = _c.current!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.sm, Space.sm, Space.screen, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _back,
              ),
              Expanded(child: _ProgressBar(value: _c.progress)),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: ListView(
              key: ValueKey(q.id),
              padding: const EdgeInsets.fromLTRB(Space.screen, Space.lg, Space.screen, Space.xl),
              children: [
                _Prompt(question: q),
                const SizedBox(height: Space.xl),
                ..._answerArea(context, q),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.screen, Space.sm, Space.screen, Space.lg),
          child: ChunkyButton(
            label: _c.isLast ? 'Finish' : 'Continue',
            loading: _c.submitting,
            onPressed: _c.canContinue ? _continue : null,
          ),
        ),
      ],
    );
  }

  List<Widget> _answerArea(BuildContext context, AssessmentQuestion q) {
    final answer = _c.answerFor(q.id);
    const gap = SizedBox(height: Space.md);

    switch (q.type) {
      case QuestionType.text:
        final ctrl = _controllerFor(q.id);
        return [
          TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            style: context.tt.titleMedium,
            decoration: InputDecoration(hintText: q.hint),
            onChanged: _c.answer,
            onSubmitted: (_) => _c.canContinue ? _continue() : null,
          ),
        ];

      case QuestionType.time:
        final presets = q.options.map(TimeSlot.parse).toList();
        final picked = answer == null ? null : TimeSlot.parse(answer.value);
        final customPicked = picked != null && !presets.contains(picked);
        return [
          for (final slot in presets) ...[
            OptionTile(
              label: formatSlot(context, slot),
              selected: picked == slot,
              onTap: () => _c.answer(slot.toApi()),
            ),
            gap,
          ],
          if (q.allowCustom)
            OptionTile(
              label: customPicked ? formatSlot(context, picked) : 'Another time…',
              leadingIcon: Icons.schedule_rounded,
              selected: customPicked,
              onTap: () async {
                final slot = await showTimeSlotSheet(
                  context,
                  title: q.prompt,
                  selected: picked ?? presets.first,
                );
                if (slot != null) _c.answer(slot.toApi(), custom: !presets.contains(slot));
              },
            ),
        ];

      case QuestionType.single:
      case QuestionType.scale:
        final options = q.options.isNotEmpty || q.type != QuestionType.scale
            ? q.options
            : [for (var i = Happiness.min; i <= Happiness.max; i++) '$i'];
        final isCustom = answer?.custom ?? false;
        final customOpen = _customOpen.contains(q.id) || isCustom;
        return [
          for (final o in options) ...[
            OptionTile(
              label: o,
              selected: !customOpen && answer?.value == o,
              onTap: () {
                setState(() => _customOpen.remove(q.id));
                _c.answer(o);
              },
            ),
            gap,
          ],
          if (q.allowCustom)
            ..._customInput(
              context,
              q,
              customOpen,
              (text) => _c.answer(text, custom: true),
              // Opening "Something else" replaces any preset pick with the typed text.
              onOpen: () => _c.answer(_controllerFor(q.id).text, custom: true),
            ),
        ];

      case QuestionType.multi:
        final selected = _c.multiFor(q.id);
        final customValues = selected.where((v) => !q.options.contains(v)).toList();
        return [
          for (final o in [...q.options, ...customValues]) ...[
            OptionTile(
              label: o,
              multiSelect: true,
              selected: selected.contains(o),
              onTap: () => _c.toggleMulti(o),
            ),
            gap,
          ],
          if (q.allowCustom)
            ..._customInput(context, q, _customOpen.contains(q.id), (text) {
              if (text.trim().isEmpty) return;
              _c.toggleMulti(text.trim());
              _controllerFor(q.id).clear();
              setState(() => _customOpen.remove(q.id));
            }, submitOnly: true),
        ];
    }
  }

  /// "Something else" tile that expands into a text field.
  List<Widget> _customInput(
    BuildContext context,
    AssessmentQuestion q,
    bool open,
    ValueChanged<String> onValue, {
    bool submitOnly = false,
    VoidCallback? onOpen,
  }) {
    final ctrl = _controllerFor(q.id);
    return [
      OptionTile(
        label: 'Something else',
        leadingIcon: Icons.edit_rounded,
        selected: open,
        onTap: () {
          setState(() => _customOpen.add(q.id));
          onOpen?.call();
        },
      ),
      if (open) ...[
        const SizedBox(height: Space.md),
        TextField(
          controller: ctrl,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: q.hint ?? 'Type your answer',
            suffixIcon: submitOnly
                ? IconButton(
                    tooltip: 'Add',
                    icon: const Icon(Icons.add_circle_rounded),
                    onPressed: () => onValue(ctrl.text),
                  )
                : null,
          ),
          onChanged: submitOnly ? null : onValue,
          onSubmitted: onValue,
        ),
      ],
    ];
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        children: [
          const Spacer(flex: 2),
          const OtterMascot(mood: Happiness.max, size: 160),
          const SizedBox(height: Space.xl),
          Text('Hi there!', style: context.tt.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: Space.md),
          Text(
            'A few quick questions about your usual day, so your journal entries can come '
            'mostly prewritten. Takes about 2 minutes.',
            style: context.tt.bodyLarge?.copyWith(color: context.jc.mutedText),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 3),
          ChunkyButton(label: 'Let\'s go', onPressed: onStart),
        ],
      ),
    );
  }
}

/// Otter with a speech bubble holding the question.
class _Prompt extends StatelessWidget {
  const _Prompt({required this.question});
  final AssessmentQuestion question;

  @override
  Widget build(BuildContext context) {
    final jc = context.jc;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const OtterMascot(size: 72),
        const SizedBox(width: Space.sm),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              color: context.cs.surface,
              border: Border.all(color: jc.cardBorder, width: 2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Radii.lg),
                topRight: Radius.circular(Radii.lg),
                bottomRight: Radius.circular(Radii.lg),
                bottomLeft: Radius.circular(Space.xs),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question.prompt, style: context.tt.titleLarge),
                if (question.subtitle != null) ...[
                  const SizedBox(height: Space.xs),
                  Text(question.subtitle!, style: context.tt.bodyMedium?.copyWith(color: jc.mutedText)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(Radii.pill),
        child: LinearProgressIndicator(
          value: v,
          minHeight: 14,
          semanticsLabel: 'Assessment progress',
          semanticsValue: '${(value * 100).round()}%',
        ),
      ),
    );
  }
}
