import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irondost_customer/app/redirect.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/features/auth/auth_repository.dart';
import 'package:irondost_customer/features/auth/otp_screen.dart';
import 'package:irondost_customer/features/auth/phone_screen.dart';
import 'package:irondost_customer/features/auth/session.dart';

import '../helpers.dart';

/// A Google customer; the API stores the number when asked, or refuses it.
class _GoogleSession extends SessionController {
  AuthFailure? refuse;
  int stored = 0;

  /// The app's router re-runs its redirect on every session change (see `routerProvider`).
  final refresh = ValueNotifier(0);

  @override
  Future<Session> build() async => const SignedIn(Profile(id: 'g1', name: 'Gina', isComplete: true));

  @override
  Future<void> phoneLinked() async {
    if (refuse != null) throw refuse!;
    stored++;
    final before = state;
    state = const AsyncData(SignedIn(Profile(id: 'g1', phone: '+919000000042', name: 'Gina', isComplete: true)));
    // What `routerProvider`'s listener does on the same change.
    if (sessionRouteKey(before) != sessionRouteKey(state)) refresh.value++;
  }
}

void main() {
  late FakeAuth auth;
  late _GoogleSession session;
  bool? result;

  /// A page that opens the add-number flow and shows what it came back with, like checkout does.
  Future<void> open(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    auth = FakeAuth()..signedIn = true;
    session = _GoogleSession();
    result = null;
    final router = GoRouter(
      initialLocation: '/checkout',
      refreshListenable: session.refresh,
      redirect: (_, _) => null,
      routes: [
        GoRoute(
          path: '/checkout',
          builder: (_, _) => Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () async => result = await context.push<bool>(Routes.addPhone),
                  child: const Text('PLACE ORDER'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: Routes.addPhone,
          builder: (_, _) => const PhoneScreen(linking: true),
          routes: [GoRoute(path: 'code', builder: (_, _) => const OtpScreen(linking: true))],
        ),
      ],
    );
    await tester.pumpWidget(
      themedRouter(
        router,
        overrides: [authRepositoryProvider.overrideWithValue(auth), sessionProvider.overrideWith(() => session)],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('PLACE ORDER'));
    await tester.pumpAndSettle();
  }

  Future<void> sendCodeTo(WidgetTester tester, String number) async {
    await tester.enterText(find.byType(TextField), number);
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
  }

  testWidgets('asks for a number, verifies it, and goes back to where the customer was with a yes', (tester) async {
    await open(tester);
    expect(find.text('Add your mobile number'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing, reason: 'already signed in with Google');

    await sendCodeTo(tester, '9000000042');
    expect(find.text('Enter the code'), findsOneWidget);
    expect(auth.linkRequests, [true]);

    await tester.enterText(find.byType(TextField), '246810');
    await tester.pumpAndSettle();

    expect(session.stored, 1);
    expect(find.text('PLACE ORDER'), findsOneWidget, reason: 'both screens are closed');
    expect(result, isTrue);
  });

  testWidgets('a number that belongs to another account stays on the code screen and says why', (tester) async {
    await open(tester);
    await sendCodeTo(tester, '9000000042');
    session.refuse = const AuthFailure(AuthFailureKind.phoneInUse);

    await tester.enterText(find.byType(TextField), '246810');
    await tester.pumpAndSettle();

    expect(find.textContaining('already linked to another IronDost account'), findsOneWidget);
    expect(find.text('Enter the code'), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('backing out returns no, so the order is not placed', (tester) async {
    await open(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('PLACE ORDER'), findsOneWidget);
    expect(result, anyOf(isNull, isFalse));
  });

  testWidgets('an account that already has a verified number finishes by itself, with nothing to type', (tester) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    auth = FakeAuth()
      ..signedIn = true
      ..verifiedPhone = true;
    session = _GoogleSession();
    result = null;
    final router = GoRouter(
      initialLocation: '/checkout',
      routes: [
        GoRoute(
          path: '/checkout',
          builder: (_, _) => Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () async => result = await context.push<bool>(Routes.addPhone),
                  child: const Text('PLACE ORDER'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(path: Routes.addPhone, builder: (_, _) => const PhoneScreen(linking: true)),
      ],
    );
    await tester.pumpWidget(
      themedRouter(router, overrides: [authRepositoryProvider.overrideWithValue(auth), sessionProvider.overrideWith(() => session)]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('PLACE ORDER'));
    await tester.pumpAndSettle();

    expect(session.stored, 1);
    expect(result, isTrue);
  });
}
