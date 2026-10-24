import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/models/time_slot.dart';
import '../theme/spacing.dart';
import 'time_format.dart';

/// Bottom sheet with every slot of the day (30-min steps by default).
/// Returns the picked slot, or null if dismissed.
Future<TimeSlot?> showTimeSlotSheet(
  BuildContext context, {
  required String title,
  required TimeSlot selected,
  TimeSlot? usual,
  int intervalMinutes = 30,
}) {
  return showModalBottomSheet<TimeSlot>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TimeSlotSheet(
      title: title,
      selected: selected,
      usual: usual,
      intervalMinutes: intervalMinutes,
    ),
  );
}

class _TimeSlotSheet extends StatefulWidget {
  const _TimeSlotSheet({
    required this.title,
    required this.selected,
    required this.usual,
    required this.intervalMinutes,
  });

  final String title;
  final TimeSlot selected;
  final TimeSlot? usual;
  final int intervalMinutes;

  @override
  State<_TimeSlotSheet> createState() => _TimeSlotSheetState();
}

class _TimeSlotSheetState extends State<_TimeSlotSheet> {
  static const _columns = 3;
  static const _rowHeight = 52.0;
  static const _gap = Space.sm;

  late final List<TimeSlot> _slots = TimeSlot.allSlots(intervalMinutes: widget.intervalMinutes);

  // Open scrolled so the selected slot sits near the top.
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: math.max(
      0,
      (_slots.indexOf(widget.selected) ~/ _columns) * (_rowHeight + _gap) - 2 * (_rowHeight + _gap),
    ),
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.65;
    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, Space.md),
            child: Text(widget.title, style: context.tt.titleLarge),
          ),
          Expanded(
            child: GridView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, Space.xl),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _columns,
                mainAxisExtent: _rowHeight,
                mainAxisSpacing: _gap,
                crossAxisSpacing: _gap,
              ),
              itemCount: _slots.length,
              itemBuilder: (context, i) {
                final slot = _slots[i];
                return _SlotChip(
                  label: formatSlot(context, slot),
                  selected: slot == widget.selected,
                  usual: slot == widget.usual,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop(slot);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.label, required this.selected, required this.usual, required this.onTap});

  final String label;
  final bool selected;
  final bool usual;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final jc = context.jc;
    final radius = BorderRadius.circular(Radii.md);
    return Semantics(
      button: true,
      selected: selected,
      label: usual ? '$label, usual' : label,
      excludeSemantics: true,
      child: Material(
        color: selected ? cs.primary : (usual ? jc.selectedTint : cs.surface),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: selected ? cs.primary : jc.cardBorder, width: 2),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: context.tt.labelLarge?.copyWith(color: selected ? cs.onPrimary : cs.onSurface),
              ),
              if (usual)
                Text(
                  'usual',
                  style: context.tt.labelSmall?.copyWith(
                    color: selected ? cs.onPrimary : jc.mutedText,
                    height: 1.1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
