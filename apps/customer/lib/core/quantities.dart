import '../data/api/export.dart';

String unitRateLabel(ItemUnit unit) => switch (unit) {
  ItemUnit.piece => 'per piece', ItemUnit.pair => 'per pair', ItemUnit.valueSet => 'per set',
  ItemUnit.kg => 'per kg (whole kg increments)', ItemUnit.$unknown => 'per unit',
};

String quantitySummary(Iterable<(ItemUnit, num)> lines) {
  final counts = <ItemUnit, num>{};
  for (final (unit, quantity) in lines) { counts[unit] = (counts[unit] ?? 0) + quantity; }
  return counts.entries.map((entry) {
    final n = entry.value; final text = n == n.toInt() ? '${n.toInt()}' : '$n';
    final label = switch (entry.key) {
      ItemUnit.piece => n == 1 ? 'item' : 'items', ItemUnit.pair => n == 1 ? 'pair' : 'pairs',
      ItemUnit.valueSet => n == 1 ? 'set' : 'sets', ItemUnit.kg => 'kg', ItemUnit.$unknown => 'units',
    };
    return '$text $label';
  }).join(' · ');
}
