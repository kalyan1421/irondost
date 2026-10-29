import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/phone.dart';
import '../../data/api_client.dart';
import 'auth_repository.dart';
import 'session.dart';

const _keep = Object();

class LoginState {
  const LoginState({
    this.phone = '',
    this.challenge,
    this.busy = false,
    this.googleBusy = false,
    this.error,
    this.resendAt,
    this.link = false,
    this.linked = false,
  });

  /// 10-digit national number.
  final String phone;
  final PhoneChallenge? challenge;
  final bool busy;

  /// The Google account picker or sign-in is running.
  final bool googleBusy;
  final AuthFailureKind? error;

  /// The code adds a number to the signed-in (Google) account instead of signing in.
  final bool link;

  /// The number was verified and the API has stored it (only in [link] mode).
  final bool linked;

  /// When "Resend code" becomes available.
  final DateTime? resendAt;

  bool get locked => error == AuthFailureKind.tooManyRequests;

  LoginState copyWith({
    String? phone,
    Object? challenge = _keep,
    bool? busy,
    bool? googleBusy,
    Object? error = _keep,
    Object? resendAt = _keep,
    bool? linked,
  }) =>
      LoginState(
        phone: phone ?? this.phone,
        challenge: identical(challenge, _keep) ? this.challenge : challenge as PhoneChallenge?,
        busy: busy ?? this.busy,
        googleBusy: googleBusy ?? this.googleBusy,
        error: identical(error, _keep) ? this.error : error as AuthFailureKind?,
        resendAt: identical(resendAt, _keep) ? this.resendAt : resendAt as DateTime?,
        link: link,
        linked: linked ?? this.linked,
      );
}

final loginProvider = NotifierProvider<LoginController, LoginState>(LoginController.new);

/// Phone → SMS code → session, or Google → session. Also adds a verified number to a Google customer ([LoginState.link]).
/// Screens read [LoginState] and call these methods.
class LoginController extends Notifier<LoginState> {
  static const resendDelay = Duration(seconds: 30);

  @override
  LoginState build() => const LoginState();

  AuthRepository get _auth => ref.read(authRepositoryProvider);

  /// Returns true when the code screen should open (code sent, or the number is locked). In [link] mode, when Android read the
  /// code itself the number is already stored, [LoginState.linked] is set and the caller should finish instead.
  Future<bool> sendCode(String phone, {bool link = false}) async {
    if (!IndianPhone.isValid(phone)) {
      state = LoginState(phone: phone, link: link, error: AuthFailureKind.invalidNumber);
      return false;
    }
    state = LoginState(phone: phone, busy: true, link: link);
    try {
      final challenge = await _auth.sendCode(phone, onAutoVerified: _autoVerified, link: link);
      state = state.copyWith(challenge: challenge, busy: false, resendAt: DateTime.now().add(resendDelay));
      if (challenge.autoVerified) await _finish(challenge);
      return true;
    } on AuthFailure catch (f) {
      state = state.copyWith(busy: false, error: f.kind);
      return f.kind == AuthFailureKind.tooManyRequests;
    } on ApiFailure catch (f) {
      state = state.copyWith(busy: false, error: f.isConnectivity ? AuthFailureKind.network : AuthFailureKind.unknown);
      return false;
    }
  }

  /// Signs in with a Google account. Returns why it did not work (null on success), so the screen can say so; a closed
  /// account picker is reported as [AuthFailureKind.googleCancelled], which needs no message.
  Future<AuthFailureKind?> signInWithGoogle() async {
    if (state.googleBusy || state.busy) return null;
    state = state.copyWith(googleBusy: true, error: null);
    try {
      await _auth.signInWithGoogle();
      await ref.read(sessionProvider.notifier).signedIn();
      state = state.copyWith(googleBusy: false);
      return null;
    } on AuthFailure catch (f) {
      state = state.copyWith(googleBusy: false);
      return f.kind;
    }
  }

  /// A Google account that already has a verified number (added earlier, but the API did not hear about it) only needs the API
  /// to read the refreshed token. Returns true when that was enough and there is nothing to type.
  Future<bool> syncLinkedPhone() async {
    if (!await _auth.hasVerifiedPhone()) return false;
    try {
      await _auth.token(forceRefresh: true);
      await ref.read(sessionProvider.notifier).phoneLinked();
      state = state.copyWith(linked: true);
      return true;
    } on AuthFailure catch (f) {
      state = state.copyWith(error: f.kind);
      return false;
    } on ApiFailure {
      return false;
    }
  }

  Future<void> resend() async {
    final previous = state.challenge;
    if (previous == null || state.busy) return;
    state = state.copyWith(busy: true, error: null);
    try {
      final challenge = await _auth.sendCode(state.phone, resendOf: previous, onAutoVerified: _autoVerified, link: state.link);
      state = state.copyWith(challenge: challenge, busy: false, resendAt: DateTime.now().add(resendDelay));
    } on AuthFailure catch (f) {
      state = state.copyWith(busy: false, error: f.kind);
    }
  }

  Future<void> verify(String code) async {
    final challenge = state.challenge;
    if (challenge == null || state.busy) return;
    state = state.copyWith(busy: true, error: null);
    try {
      await _auth.confirmCode(challenge, code);
      await _finish(challenge);
      state = state.copyWith(busy: false);
    } on AuthFailure catch (f) {
      state = state.copyWith(busy: false, error: f.kind);
    } on ApiFailure catch (f) {
      state = state.copyWith(busy: false, error: f.isConnectivity ? AuthFailureKind.network : AuthFailureKind.unknown);
    }
  }

  /// The code was accepted: start the session, or (adding a number) have the API store it.
  Future<void> _finish(PhoneChallenge challenge) async {
    final session = ref.read(sessionProvider.notifier);
    if (challenge.link) {
      await session.phoneLinked();
      state = state.copyWith(linked: true);
    } else {
      await session.signedIn();
    }
  }

  void clearError() {
    if (state.error != null) state = state.copyWith(error: null);
  }

  /// Start over with another number.
  void reset() => state = LoginState(phone: state.phone, link: state.link);

  Future<void> _autoVerified() async {
    final challenge = state.challenge;
    try {
      await _finish(challenge ?? PhoneChallenge(phone: state.phone, verificationId: '', link: state.link));
    } on AuthFailure catch (f) {
      state = state.copyWith(error: f.kind);
    } on ApiFailure {
      state = state.copyWith(error: AuthFailureKind.unknown);
    }
  }
}
