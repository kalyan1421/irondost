/// Compares dotted versions ("2.0.10" > "2.0.9"). Missing parts count as 0; any build
/// suffix after "+" or "-" is ignored.
int compareVersions(String a, String b) {
  List<int> parts(String v) =>
      v.split(RegExp(r'[+-]')).first.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
  final x = parts(a);
  final y = parts(b);
  for (var i = 0; i < (x.length > y.length ? x.length : y.length); i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d.sign;
  }
  return 0;
}
