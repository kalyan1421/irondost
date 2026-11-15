import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/auth/add_phone_screen.dart';
import 'package:irondost_customer/features/auth/session.dart';

import '../helpers.dart';

/// A Google customer; the API stores the number they type, or refuses it.
class _GoogleSession extends SessionController {
  _GoogleSession({this.phone});

  /// A number the customer typed earlier (not verified by SMS).
  final String? phone;
  Object? refuse;
  final saved = <String>[];

  @override
  Future<Session> build() async => SignedIn(Profile(id: 'g1', phone: phone, name: 'Gina', isComplete: true));

  @override
  Future<void> savePhone(String phone) async {
    if (refuse != null) throw refuse!;
    saved.add(phone);
    state = AsyncData(SignedIn(Profile(id: 'g1', phone: '+91$phone', name: 'Gina', isComplete: true)));
  }
}

void main() {
  late _GoogleSession session;
  bool? result;

  /// A page that opens the add-number screen and shows what it came back with, like checkout does.
  Future<void> open(WidgetTester tester, {String? phone}) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    session = _GoogleSession(phone: phone);
    result = null;
    final router = GoRouter(
      initialLocation: '/checkout',
      routes: [
        GoRoute(
          path: '/checkout',
          builder: (_, _) => Scaffold(
            body: Center(
              // Checkout watches the session, so by the time the number screen opens it is loaded.
              child: Consumer(
                builder: (context, ref, _) {
                  ref.watch(sessionProvider);
                  return TextButton(
                    onPressed: () async => result = await context.push<bool>(Routes.addPhone),
                    child: const Text('PLACE ORDER'),
                  );
                },
              ),
            ),
          ),
        ),
        GoRoute(path: Routes.addPhone, builder: (_, _) => const AddPhoneScreen()),
      ],
    );
    await tester.pumpWidget(themedRouter(router, overrides: [sessionProvider.overrideWith(() => session)]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PLACE ORDER'));
    await tester.pumpAndSettle();
  }

  String typed(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField)).controller!.text;

  Future<void> save(WidgetTester tester, String number) async {
    await tester.enterText(find.byType(TextField), number);
    await tester.tap(find.text('Save number'));
    await tester.pumpAndSettle();
  }

  testWidgets('saves the typed number straight away, with no code, and goes back to where the customer was with a yes', (tester) async {
    await open(tester);
    expect(find.text('Add your mobile number'), findsOneWidget);
    expect(find.textContaining('code'), findsNothing, reason: 'no SMS code is asked for');

    await save(tester, '98765 43210');

    expect(session.saved, ['9876543210']);
    expect(find.text('PLACE ORDER'), findsOneWidget, reason: 'the screen is closed');
    expect(result, isTrue);
  });

  testWidgets('accepts a number pasted with +91', (tester) async {
    await open(tester);
    await save(tester, '+91 98765 43210');
    expect(session.saved, ['9876543210']);
  });

  testWidgets('a number that is not a 10-digit Indian mobile is not sent', (tester) async {
    await open(tester);
    await save(tester, '12345');

    expect(find.text('Enter a 10-digit mobile number.'), findsOneWidget);
    expect(session.saved, isEmpty);
    expect(result, isNull);
  });

  testWidgets('says so when the phone is offline, and keeps what was typed', (tester) async {
    await open(tester);
    session.refuse = const ApiFailure(ApiFailureKind.offline);
    await save(tester, '9876543210');

    expect(find.text("You're offline. Check your connection and try again."), findsOneWidget);
    expect(typed(tester), '98765 43210');
    expect(result, isNull);
  });

  testWidgets('shows the server\'s refusal of the number', (tester) async {
    await open(tester);
    session.refuse = const ApiFailure(ApiFailureKind.rejected, statusCode: 400, code: 'INVALID_PHONE');
    await save(tester, '9876543210');

    expect(find.text('Enter a 10-digit mobile number.'), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('a number typed earlier is filled in, so it can be corrected', (tester) async {
    await open(tester, phone: '+919000000042');
    expect(find.text('Change your mobile number'), findsOneWidget);
    expect(typed(tester), '90000 00042');

    await save(tester, '9111111111');
    expect(session.saved, ['9111111111']);
    expect(result, isTrue);
  });

  testWidgets('backing out returns no, so the order is not placed', (tester) async {
    await open(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('PLACE ORDER'), findsOneWidget);
    expect(result, anyOf(isNull, isFalse));
  });
}
