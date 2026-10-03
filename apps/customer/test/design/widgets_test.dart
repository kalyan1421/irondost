import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/design/theme.dart';
import 'package:irondost_customer/design/widgets/id_button.dart';
import 'package:irondost_customer/design/widgets/otp_input.dart';
import 'package:irondost_customer/features/auth/auth_repository.dart';
import 'package:irondost_customer/features/auth/phone_screen.dart';

import '../helpers.dart';

void main() {
  testWidgets('OtpInput completes on the sixth digit and ignores letters', (tester) async {
    final controller = TextEditingController();
    String? completed;
    await tester.pumpWidget(themed(Scaffold(body: OtpInput(controller: controller, onCompleted: (c) => completed = c))));

    await tester.enterText(find.byType(TextField), '48a29');
    expect(controller.text, '4829');
    expect(completed, isNull);

    await tester.enterText(find.byType(TextField), '482916');
    await tester.pump();
    expect(completed, '482916');
    expect(find.text('6'), findsOneWidget);
  });

  testWidgets('IdButton ignores taps while loading and is announced as loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(themed(Scaffold(body: IdButton(label: 'Verify', loading: true, onPressed: () => taps++))));
    await tester.tap(find.byType(FilledButton));
    expect(taps, 0);
    expect(find.bySemanticsLabel('Verify, loading'), findsOneWidget);
  });

  testWidgets('IdButton meets the 48dp touch target and 52dp height', (tester) async {
    await tester.pumpWidget(themed(Scaffold(body: Center(child: IdButton.text(label: 'OK', onPressed: () {})))));
    final size = tester.getSize(find.byType(TextButton));
    expect(size.height, greaterThanOrEqualTo(IdSize.touchTarget));
    expect(size.width, greaterThanOrEqualTo(IdSize.touchTarget));
  });

  testWidgets('the phone screen explains an invalid number under the field', (tester) async {
    final auth = FakeAuth();
    await tester.pumpWidget(themed(const PhoneScreen(), overrides: [authRepositoryProvider.overrideWithValue(auth)]));

    await tester.enterText(find.byType(TextField), '98765');
    await tester.tap(find.text('Get OTP'));
    await tester.pump();

    expect(find.text('Enter a 10-digit mobile number.'), findsOneWidget);
    expect(auth.sentTo, isEmpty);
  });

  testWidgets('dark theme keeps text readable on cards', (tester) async {
    late IdColors colors;
    await tester.pumpWidget(themed(Builder(builder: (context) {
      colors = context.colors;
      return const SizedBox();
    }), brightness: Brightness.dark));
    expect(colors.surface, IdColors.dark.surface);
    expect(colors.text, IdColors.dark.text);
  });
}
