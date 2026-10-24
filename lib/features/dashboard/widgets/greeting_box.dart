import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/widgets/otter_mascot.dart';

/// "Hey {name}" in a rounded box, with this launch's otter face on the right.
class GreetingBox extends StatelessWidget {
  const GreetingBox({super.key, required this.name, required this.otterMood});

  final String name;

  /// 1-5, picked once per app launch.
  final int otterMood;

  static String greetingText(String name) {
    final n = name.trim();
    return n.isEmpty ? 'Hey' : 'Hey $n';
  }

  @override
  Widget build(BuildContext context) {
    final jc = context.jc;
    final greeting = greetingText(name);
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.fromLTRB(Space.md, Space.xs, Space.xs, Space.xs),
      decoration: BoxDecoration(
        color: context.cs.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: jc.cardBorder, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: greeting,
              excludeSemantics: true,
              child: Text(
                greeting,
                style: context.tt.titleLarge,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: Space.xs),
          OtterMascot(mood: otterMood, size: 44, animate: false),
        ],
      ),
    );
  }
}
