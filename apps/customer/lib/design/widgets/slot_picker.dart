import 'package:flutter/material.dart';

import '../../core/slots.dart';
import '../theme.dart';

/// A row of date chips: "TODAY 3", "SAT 4". Scrolls sideways when the days don't fit.
class DateStrip extends StatelessWidget {
  const DateStrip({
    super.key,
    required this.label,
    required this.dates,
    required this.selected,
    required this.today,
    required this.onSelect,
  });

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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (i, date) in dates.indexed) ...[
              if (i > 0) const SizedBox(width: IdSpace.s2),
              Semantics(
                inMutuallyExclusiveGroup: true,
                checked: date == selected,
                label: '${date == today ? 'Today, ' : ''}${dayLong(date)}',
                excludeSemantics: true,
                child: Material(
                  color: date == selected ? c.primarySoft : c.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(IdRadius.sm),
                    side: BorderSide(
                      color: date == selected ? c.primary : c.borderStrong,
                      width: date == selected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(IdRadius.sm),
                    onTap: () => onSelect(date),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 64,
                        minHeight: 72,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: IdSpace.s3,
                          vertical: IdSpace.s3,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dayChipTop(date, today: today),
                              style: t.caption.copyWith(
                                color: date == selected
                                    ? c.onPrimarySoft
                                    : c.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              dayChipNumber(date),
                              style: t.titleLg.copyWith(
                                color: date == selected
                                    ? c.onPrimarySoft
                                    : c.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One time window: name, hours, and a radio. A closed window stays listed, dimmed, with [closedNote].
class SlotTile extends StatelessWidget {
  const SlotTile({
    super.key,
    required this.name,
    required this.window,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.closedNote = 'Closed',
  });

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
          color: c.surface,
          shape: Border(bottom: BorderSide(color: c.border)),
          child: InkWell(
            borderRadius: BorderRadius.circular(IdRadius.md),
            onTap: enabled ? onTap : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: t.label.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            detail,
                            style: t.caption.copyWith(color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? c.primary : c.borderStrong,
                          width: selected ? 6 : 2,
                        ),
                      ),
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

/// A single-line radio row ("I booked by mistake"), the way the design lists reasons and short choices.
class ReasonTile extends StatelessWidget {
  const ReasonTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: Border(bottom: BorderSide(color: c.border)),
        child: InkWell(
          borderRadius: BorderRadius.circular(IdRadius.md),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: IdSize.touchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: context.text.bodyLg)),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? c.primary : c.borderStrong,
                        width: selected ? 6 : 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
