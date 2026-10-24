import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/models/entry.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/widgets/time_format.dart';
import 'history_tile.dart';

/// Scrollable log history: day headers + entry tiles, newest day first.
/// Used both in the dashboard's history viewport and the expanded view.
class HistoryList extends StatelessWidget {
  const HistoryList({super.key, required this.groups, this.controller, this.padding = EdgeInsets.zero});

  final List<(DateTime, List<LogEntry>)> groups;
  final ScrollController? controller;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return ListView(
        controller: controller,
        padding: padding,
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [SizedBox(height: Space.xl), _EmptyHistory()],
      );
    }
    return CustomScrollView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(padding: EdgeInsets.only(top: padding.top)),
        for (final (i, (day, entries)) in groups.indexed) ...[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(padding.left, i == 0 ? 0 : Space.lg, padding.right, Space.sm),
            sliver: SliverToBoxAdapter(
              child: Semantics(
                header: true,
                child: Text(
                  formatDayHeader(context, day),
                  style: context.tt.titleSmall?.copyWith(color: context.jc.mutedText),
                ),
              ),
            ),
          ),
          SliverPadding(
            // Room for the cards' 3D bottom edge.
            padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, Depth.card),
            sliver: SliverList.separated(
              itemCount: entries.length,
              itemBuilder: (_, i) => HistoryTile(entry: entries[i]),
              separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
            ),
          ),
        ],
        SliverPadding(padding: EdgeInsets.only(bottom: padding.bottom + Space.lg)),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.screen),
      child: Text(
        'No entries yet. Your first one takes about 10 seconds.',
        textAlign: TextAlign.center,
        style: context.tt.bodyMedium?.copyWith(color: context.jc.mutedText),
      ),
    );
  }
}
