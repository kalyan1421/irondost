import 'package:flutter/material.dart';

import '../../core/slots.dart';
import '../theme.dart';

/// A row of date chips: "TODAY 3", "SAT 4". Scrolls sideways when the days don't fit.
class DateStrip extends StatelessWidget {
  const DateStrip({super.key, required this.label, required this.dates, required this.selected, required this.today, required this.onSelect});

  /// Read out by screen readers: "Pickup date".
  final String label;
  final List<String> dates;
  final String selected;

  /// The API's first day; shown as "Today".
  final String today;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      container: true,
      label: label,
      child: SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: dates.length,
          separatorBuilder: (_, _) => const SizedBox(width: IdSpace.s2),
          itemBuilder: (_, i) {
            final date = dates[i];
            final on = date == selected;
            final fg = on ? c.onPrimary : c.text;
            return Semantics(
              inMutuallyExclusiveGroup: true,
              checked: on,
              label: dayLong(date, today: today),
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(IdRadius.md),
                onTap: () => onSelect(date),
                child: Container(
                  width: 64,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: on ? c.primary : c.surface,
                    borderRadius: BorderRadius.circular(IdRadius.md),
                    border: on ? null : Border.all(color: c.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayChipTop(date, today: today).toUpperCase(),
                        style: t.caption.copyWith(color: on ? c.onPrimary : c.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                      ),
                      Text(dayChipNumber(date), style: t.titleLg.copyWith(color: fg)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One time window: name, hours, and a radio. A closed window stays listed, dimmed, with [closedNote].
class SlotTile extends StatelessWidget {
  const SlotTile({super.key, required this.name, required this.window, required this.selected, required this.enabled, required this.onTap, this.closedNote = 'Closed'});

  final String name;

  /// "7 – 11 AM".
  final String window;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  /// Appended to the hours when [enabled] is false: "Closed", "Too soon".
  final String closedNote;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final detail = enabled ? window : '$window · $closedNote';
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      label: '$name, $detail',
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: selected ? c.primarySoft : c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(IdRadius.md),
            side: BorderSide(color: selected ? c.primary : c.border, width: selected ? 2 : 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(IdRadius.md),
            onTap: enabled ? onTap : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: IdSpace.s4, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: t.label.copyWith(fontWeight: FontWeight.w600)),
                          Text(detail, style: t.caption.copyWith(color: c.textMuted)),
                        ],
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? c.primary : c.borderStrong, width: selected ? 6 : 2)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
