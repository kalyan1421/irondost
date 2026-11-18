import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/features/support/support.dart';
import '../helpers.dart';

void main() {
  for (final throws in [false, true]) {
    testWidgets('email launch ${throws ? 'exception' : 'failure'} keeps contact and order context', (tester) async {
      Uri? attempted;
      await tester.pumpWidget(themed(Scaffold(body: Builder(builder: (context) => TextButton(
        onPressed: () => Support.mail('help@example.com', context: context, orderNumber: 'ID 1046',
          fallback: const Support(phone: '+919000000000', email: 'help@example.com')),
        child: const Text('Help'),
      ))), overrides: [supportLauncherProvider.overrideWithValue((uri) async {
        attempted = uri;
        if (throws) throw StateError('No email application');
        return false;
      })]));
      await tester.tap(find.text('Help'));
      await tester.pumpAndSettle();
      expect(attempted!.queryParameters['subject'], 'Help with order ID 1046');
      expect(attempted!.queryParameters['body'], contains('Order: ID 1046'));
      expect(find.text("Couldn't open the email app"), findsOneWidget);
      expect(find.text('help@example.com'), findsOneWidget);
      expect(find.text('Copy contact'), findsOneWidget);
      expect(find.text('Call support'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
