import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/app/env.dart';
import 'package:irondost_customer/features/auth/auth_repository.dart';
import 'package:irondost_customer/features/auth/name_screen.dart';
import 'package:irondost_customer/features/auth/phone_screen.dart';
import 'package:irondost_customer/features/auth/session.dart';
import 'package:irondost_customer/features/auth/welcome_screen.dart';

import '../helpers.dart';

/// The name screen, built once the session has loaded (the router only shows it to a signed-in customer).
Widget _afterSession(Widget screen) => Consumer(
  builder: (context, ref, _) => ref.watch(sessionProvider).hasValue ? screen : const SizedBox.shrink(),
);

/// A signed-in customer with a given profile and a record of sign-outs.
class _Session extends SessionController {
  _Session(this.profile);
  final Profile profile;
  int signOuts = 0;

  @override
  Future<Session> build() async => SignedIn(profile);

  @override
  Future<void> signOut() async {
    signOuts++;
    state = const AsyncData(SignedOut());
  }
}

/// Runs [body] as if on [platform]. The override has to be cleared before the test body ends.
Future<void> onPlatform(TargetPlatform platform, Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  group('Continue with Google', () {
    testWidgets('is offered on Android', (tester) => onPlatform(TargetPlatform.android, () async {
      await tester.pumpWidget(themed(const WelcomeScreen()));
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('or'), findsOneWidget);
    }));

    testWidgets('is left out on iPhone, where Sign in with Apple would be required beside it', (tester) => onPlatform(TargetPlatform.iOS, () async {
      await tester.pumpWidget(themed(const WelcomeScreen()));
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('Continue with Google'), findsNothing);
      expect(find.text('or'), findsNothing);
    }));

    testWidgets('is left out of the mobile number screen on iPhone too', (tester) => onPlatform(TargetPlatform.iOS, () async {
      await tester.pumpWidget(themed(const PhoneScreen(), overrides: [authRepositoryProvider.overrideWithValue(FakeAuth())]));
      expect(find.text('Send code'), findsOneWidget);
      expect(find.text('Continue with Google'), findsNothing);
    }));
  });

  group('Name screen', () {
    testWidgets('shows the email a Google customer already has, so saving cannot erase it', (tester) async {
      final session = _Session(const Profile(id: 'g1', email: 'gina@example.com', isComplete: false));
      await tester.pumpWidget(themed(_afterSession(const NameScreen()), overrides: [sessionProvider.overrideWith(() => session)]));
      await tester.pumpAndSettle();
      expect(find.text('gina@example.com'), findsOneWidget);
    });

    testWidgets('lets someone who picked the wrong account sign out', (tester) async {
      final session = _Session(const Profile(id: 'g1', isComplete: false));
      await tester.pumpWidget(themed(_afterSession(const NameScreen()), overrides: [sessionProvider.overrideWith(() => session)]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use a different account'));
      await tester.pumpAndSettle();
      expect(session.signOuts, 1);
    });
  });

  group('release configuration', () {
    test('accepts the production settings', () {
      expect(AppEnv.problemFor(apiBaseUrl: 'https://api.example.com', authMode: 'firebase', flavor: 'prod'), isNull);
    });

    test('refuses a dev flavor, dev sign-in or a non-https address', () {
      expect(AppEnv.problemFor(apiBaseUrl: 'https://api.example.com', authMode: 'firebase', flavor: 'dev'), contains('FLAVOR'));
      expect(AppEnv.problemFor(apiBaseUrl: 'https://api.example.com', authMode: 'dev', flavor: 'prod'), contains('AUTH_MODE'));
      expect(AppEnv.problemFor(apiBaseUrl: 'http://localhost:4000', authMode: 'firebase', flavor: 'prod'), contains('https'));
    });
  });
}
