import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/features/auth/auth_repository.dart';
import 'package:irondost_customer/features/auth/login_controller.dart';
import 'package:irondost_customer/features/auth/session.dart';

import '../helpers.dart';

/// Session that records sign-ins instead of calling the API.
class _FakeSession extends SessionController {
  int signIns = 0;
  int phoneLinks = 0;

  /// Set to make the API refuse the number, as it does when another account has it.
  AuthFailure? linkFailure;

  @override
  Future<Session> build() async => const SignedOut();

  @override
  Future<void> signedIn() async {
    signIns++;
    state = const AsyncData(SignedIn(Profile(id: 'u1', phone: '+919876543210', isComplete: false)));
  }

  @override
  Future<void> phoneLinked() async {
    phoneLinks++;
    if (linkFailure != null) throw linkFailure!;
    state = const AsyncData(SignedIn(Profile(id: 'g1', phone: '+919876543210', name: 'Gina', isComplete: true)));
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

  group('Google', () {
    test('signs in with Google and starts the session', () async {
      expect(await login().signInWithGoogle(), isNull);
      expect(auth.googleSignIns, 1);
      expect(session.signIns, 1);
      expect(state().googleBusy, isFalse);
    });

    test('closing the account picker is reported as cancelled and signs nobody in', () async {
      auth.googleFailure = const AuthFailure(AuthFailureKind.googleCancelled);
      expect(await login().signInWithGoogle(), AuthFailureKind.googleCancelled);
      expect(session.signIns, 0);
      expect(state().googleBusy, isFalse);
    });

    test('a build without Google set up says so', () async {
      auth.googleFailure = const AuthFailure(AuthFailureKind.googleUnavailable);
      expect(await login().signInWithGoogle(), AuthFailureKind.googleUnavailable);
      expect(session.signIns, 0);
    });
  });

  group('adding a number to a Google account', () {
    test('verifies the number with a link request and has the API store it, without signing in again', () async {
      expect(await login().sendCode('9876543210', link: true), isTrue);
      expect(auth.linkRequests, [true]);
      expect(state().link, isTrue);

      await login().verify('482916');
      expect(auth.verifiedPhone, isTrue);
      expect(session.phoneLinks, 1);
      expect(session.signIns, 0);
      expect(state().linked, isTrue);
      expect(state().error, isNull);
    });

    test('a number that belongs to another account is refused, with a clear reason and nothing stored', () async {
      await login().sendCode('9876543210', link: true);
      session.linkFailure = const AuthFailure(AuthFailureKind.phoneInUse);
      await login().verify('482916');
      expect(state().error, AuthFailureKind.phoneInUse);
      expect(state().linked, isFalse);
      expect(state().busy, isFalse);
    });

    test('Firebase refusing the link (number already on another login) shows the same reason', () async {
      await login().sendCode('9876543210', link: true);
      auth.confirmFailure = const AuthFailure(AuthFailureKind.phoneInUse);
      await login().verify('482916');
      expect(state().error, AuthFailureKind.phoneInUse);
      expect(session.phoneLinks, 0);
    });

    test('resend keeps adding a number rather than signing in', () async {
      await login().sendCode('9876543210', link: true);
      await login().resend();
      expect(auth.linkRequests, [true, true]);
    });

    test('an account that already has a verified number only needs the API to read it', () async {
      auth.verifiedPhone = true;
      expect(await login().syncLinkedPhone(), isTrue);
      expect(session.phoneLinks, 1);
      expect(state().linked, isTrue);
    });

    test('with no verified number yet there is nothing to sync', () async {
      expect(await login().syncLinkedPhone(), isFalse);
      expect(session.phoneLinks, 0);
    });

    test('sending a code to a bad number does not link anything', () async {
      expect(await login().sendCode('12345', link: true), isFalse);
      expect(state().error, AuthFailureKind.invalidNumber);
      expect(auth.sentTo, isEmpty);
    });
  });
}
