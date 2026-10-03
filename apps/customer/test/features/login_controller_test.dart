import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/features/auth/auth_repository.dart';
import 'package:irondost_customer/features/auth/login_controller.dart';
import 'package:irondost_customer/features/auth/session.dart';

import '../helpers.dart';

/// Session that records sign-ins instead of calling the API.
class _FakeSession extends SessionController {
  int signIns = 0;

  @override
  Future<Session> build() async => const SignedOut();

  @override
  Future<void> signedIn() async {
    signIns++;
    state = const AsyncData(SignedIn(Profile(id: 'u1', phone: '+919876543210', isComplete: false)));
  }
}

void main() {
  late FakeAuth auth;
  late _FakeSession session;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuth();
    session = _FakeSession();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        sessionProvider.overrideWith(() => session),
      ],
    );
    addTearDown(container.dispose);
  });

  LoginController login() => container.read(loginProvider.notifier);
  LoginState state() => container.read(loginProvider);

  test('rejects a number that is not a 10-digit Indian mobile, without sending', () async {
    expect(await login().sendCode('12345'), isFalse);
    expect(state().error, AuthFailureKind.invalidNumber);
    expect(auth.sentTo, isEmpty);
  });

  test('sends the code, then signs in with it', () async {
    expect(await login().sendCode('9876543210'), isTrue);
    expect(state().challenge?.phone, '9876543210');
    expect(state().resendAt, isNotNull);

    await login().verify('482916');
    expect(auth.signedIn, isTrue);
    expect(session.signIns, 1);
    expect(state().error, isNull);
  });

  test('keeps the customer on the code screen after a wrong code', () async {
    await login().sendCode('9876543210');
    auth.confirmFailure = const AuthFailure(AuthFailureKind.invalidCode);
    await login().verify('000000');
    expect(state().error, AuthFailureKind.invalidCode);
    expect(state().busy, isFalse);
    expect(session.signIns, 0);
  });

  test('locks after too many requests and still opens the code screen to explain', () async {
    auth.sendFailure = const AuthFailure(AuthFailureKind.tooManyRequests);
    expect(await login().sendCode('9876543210'), isTrue);
    expect(state().locked, isTrue);
  });

  test('resend uses the previous challenge', () async {
    await login().sendCode('9876543210');
    await login().resend();
    expect(auth.sentTo, ['9876543210', '9876543210']);
    expect(state().challenge?.verificationId, 'v-2');
  });
}
