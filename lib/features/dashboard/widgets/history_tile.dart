import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/models/entry.dart';
import '../../../core/models/happiness.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/widgets/journey_card.dart';
import '../../../shared/widgets/time_format.dart';

/// One saved entry in the dashboard log history.
// TODO(backend): tapping could open the entry for editing once the API has
// `PUT /entries/{id}` (not in the contract yet).
class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.entry});

  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final time = formatSlot(context, entry.time);
    return JourneyCard(
      padding: const EdgeInsets.all(Space.md),
      semanticLabel: '$time. ${entry.text} Felt ${Happiness.phrase(entry.happiness)}.',
      child: ExcludeSemantics(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.text, style: context.tt.bodyMedium),
              const SizedBox(height: Space.xs),
              Text(time, style: context.tt.labelMedium?.copyWith(color: context.jc.mutedText)),
            ],
          ),
        ),
      ),
    );
  }
}
