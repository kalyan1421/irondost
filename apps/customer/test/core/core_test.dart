import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/core/money.dart';
import 'package:irondost_customer/core/phone.dart';
import 'package:irondost_customer/core/version.dart';

void main() {
  group('IndianPhone', () {
    test('accepts pasted numbers with country code, zero or spaces', () {
      expect(IndianPhone.national('+91 98765 43210'), '9876543210');
      expect(IndianPhone.national('09876543210'), '9876543210');
      expect(IndianPhone.national('98765-43210'), '9876543210');
    });

    test('validates Indian mobile numbers', () {
      expect(IndianPhone.isValid('9876543210'), isTrue);
      expect(IndianPhone.isValid('5876543210'), isFalse, reason: 'mobiles start with 6–9');
      expect(IndianPhone.isValid('987654321'), isFalse);
    });

    test('formats for display', () {
      expect(IndianPhone.format('9876543210'), '98765 43210');
      expect(IndianPhone.format('9876543210', withCode: true), '+91 98765 43210');
      expect(IndianPhone.display('+919063290012'), '+91 90632 90012');
      expect(IndianPhone.e164('9876543210'), '+919876543210');
    });

    test('the formatter groups digits and stops at ten', () {
      final f = IndianPhoneFormatter();
      TextEditingValue type(String s) => f.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: s));
      expect(type('987654').text, '98765 4');
      expect(type('+91 98765 43210').text, '98765 43210');
      expect(type('98765432101').text, '98765 43210');
    });
  });

  group('rupees', () {
    test('shows decimals only when there are paise', () {
      expect(rupees(1500), '₹15');
      expect(rupees(1250), '₹12.50');
      expect(rupees(12500000), '₹1,25,000');
    });
  });

  group('compareVersions', () {
    test('compares numerically, part by part', () {
      expect(compareVersions('2.0.10', '2.0.9'), 1);
      expect(compareVersions('1.6.2', '2.0.0'), -1);
      expect(compareVersions('2.0', '2.0.0'), 0);
      expect(compareVersions('2.0.0+100', '2.0.0'), 0);
    });
  });
}
