import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/phone.dart';
import 'auth_repository.dart';
import 'session.dart';

const _keep = Object();

class LoginState {
  const LoginState({this.phone = '', this.challenge, this.busy = false, this.error, this.resendAt});

  /// 10-digit national number.
  final String phone;
  final PhoneChallenge? challenge;
  final bool busy;
  final AuthFailureKind? error;

  /// When "Resend code" becomes available.
  final DateTime? resendAt;

  bool get locked => error == AuthFailureKind.tooManyRequests;

  LoginState copyWith({String? phone, Object? challenge = _keep, bool? busy, Object? error = _keep, Object? resendAt = _keep}) =>
      LoginState(
        phone: phone ?? this.phone,
        challenge: identical(challenge, _keep) ? this.challenge : challenge as PhoneChallenge?,
        busy: busy ?? this.busy,
        error: identical(error, _keep) ? this.error : error as AuthFailureKind?,
        resendAt: identical(resendAt, _keep) ? this.resendAt : resendAt as DateTime?,
      );
}

final loginProvider = NotifierProvider<LoginController, LoginState>(LoginController.new);

/// Phone → SMS code → session. Screens read [LoginState] and call these methods.
class LoginController extends Notifier<LoginState> {
  static const resendDelay = Duration(seconds: 30);

  @override
  LoginState build() => const LoginState();

  AuthRepository get _auth => ref.read(authRepositoryProvider);

  /// Returns true when the code screen should open (code sent, or the number is locked).
  Future<bool> sendCode(String phone) async {
    if (!IndianPhone.isValid(phone)) {
      state = state.copyWith(phone: phone, error: AuthFailureKind.invalidNumber);
      return false;
    }
    state = LoginState(phone: phone, busy: true);
    try {
      final challenge = await _auth.sendCode(phone, onAutoVerified: _autoVerified);
      state = state.copyWith(challenge: challenge, busy: false, resendAt: DateTime.now().add(resendDelay));
      if (challenge.autoVerified) await ref.read(sessionProvider.notifier).signedIn();
      return true;
    } on AuthFailure catch (f) {
      state = state.copyWith(busy: false, error: f.kind);
      return f.kind == AuthFailureKind.tooManyRequests;
    }
  }

  Future<void> resend() async {
    final previous = state.challenge;
    if (previous == null || state.busy) return;
    state = state.copyWith(busy: true, error: null);
    try {
      final challenge = await _auth.sendCode(state.phone, resendOf: previous, onAutoVerified: _autoVerified);
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
      await ref.read(sessionProvider.notifier).signedIn();
      state = state.copyWith(busy: false);
    } on AuthFailure catch (f) {
      state = state.copyWith(busy: false, error: f.kind);
    }
  }

  void clearError() {
    if (state.error != null) state = state.copyWith(error: null);
  }

  /// Start over with another number.
  void reset() => state = LoginState(phone: state.phone);

  void _autoVerified() => ref.read(sessionProvider.notifier).signedIn();
}
