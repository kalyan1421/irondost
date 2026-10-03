import 'package:flutter/services.dart';

/// Indian mobile numbers: 10 digits starting with 6–9, shown as "98765 43210".
abstract final class IndianPhone {
  static final _valid = RegExp(r'^[6-9]\d{9}$');

  /// The 10-digit national number from whatever was typed or pasted (+91, 0, spaces, dashes).
  static String national(String input) {
    var d = input.replaceAll(RegExp(r'\D'), '');
    if (d.length == 12 && d.startsWith('91')) d = d.substring(2);
    if (d.length == 11 && d.startsWith('0')) d = d.substring(1);
    return d;
  }

  static bool isValid(String national) => _valid.hasMatch(national);

  static String e164(String national) => '+91$national';

  /// "98765 43210" while typing; "+91 98765 43210" with [withCode].
  static String format(String national, {bool withCode = false}) {
    final d = national.length > 10 ? national.substring(0, 10) : national;
    final grouped = d.length > 5 ? '${d.substring(0, 5)} ${d.substring(5)}' : d;
    return withCode ? '+91 $grouped' : grouped;
  }

  /// "+919876543210" → "+91 98765 43210"; anything else is returned unchanged.
  static String display(String e164) {
    final n = national(e164);
    return isValid(n) ? format(n, withCode: true) : e164;
  }
}

/// Keeps the phone field to 10 digits, grouped "98765 43210", accepting pasted "+91…" numbers.
class IndianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = IndianPhone.national(newValue.text);
    if (digits.length > 10) digits = digits.substring(0, 10);
    final text = IndianPhone.format(digits);
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
