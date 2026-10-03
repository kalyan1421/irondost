import 'package:intl/intl.dart';

final _whole = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _paise = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

/// Paise → "₹15", "₹1,250", "₹12.50" (decimals only when there are paise).
String rupees(num paise) {
  final amount = paise / 100;
  return paise % 100 == 0 ? _whole.format(amount) : _paise.format(amount);
}
