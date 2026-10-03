import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../app/env.dart';
import '../../core/phone.dart';

enum AuthFailureKind {
  invalidNumber,
  invalidCode,
  codeExpired,

  /// Firebase's per-number or per-device limit; the customer has to wait.
  tooManyRequests,
  network,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.kind, [this.message]);
  final AuthFailureKind kind;
  final String? message;

  @override
  String toString() => 'AuthFailure($kind, $message)';
}

/// A code was sent to [phone] (10-digit national number). [autoVerified] means Android
/// read the SMS itself and the customer is already signed in.
class PhoneChallenge {
  const PhoneChallenge({required this.phone, required this.verificationId, this.resendToken, this.autoVerified = false});
  final String phone;
  final String verificationId;
  final int? resendToken;
  final bool autoVerified;
}

/// Phone-number sign-in. The API only ever sees the resulting ID token.
abstract class AuthRepository {
  /// Whether a previous sign-in is still on this phone.
  Future<bool> hasCredentials();

  /// The bearer token for API calls, or null when signed out.
  Future<String?> token({bool forceRefresh = false});

  /// Sends an SMS code. [onAutoVerified] runs if Android verifies the number without the code.
  Future<PhoneChallenge> sendCode(String phone, {PhoneChallenge? resendOf, void Function()? onAutoVerified});

  Future<void> confirmCode(PhoneChallenge challenge, String code);

  Future<void> signOut();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AppEnv.devAuth ? DevAuthRepository() : FirebaseAuthRepository(FirebaseAuth.instance),
);

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);
  final FirebaseAuth _auth;

  @override
  Future<bool> hasCredentials() async => _auth.currentUser != null;

  @override
  Future<String?> token({bool forceRefresh = false}) async => _auth.currentUser?.getIdToken(forceRefresh);

  @override
  Future<PhoneChallenge> sendCode(String phone, {PhoneChallenge? resendOf, void Function()? onAutoVerified}) {
    final result = Completer<PhoneChallenge>();
    _auth.verifyPhoneNumber(
      phoneNumber: IndianPhone.e164(phone),
      forceResendingToken: resendOf?.resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        try {
          await _auth.signInWithCredential(credential);
          if (!result.isCompleted) {
            result.complete(PhoneChallenge(phone: phone, verificationId: '', autoVerified: true));
          } else {
            onAutoVerified?.call();
          }
        } on FirebaseAuthException catch (e) {
          if (!result.isCompleted) result.completeError(_map(e));
        }
      },
      verificationFailed: (e) {
        if (!result.isCompleted) result.completeError(_map(e));
      },
      codeSent: (verificationId, resendToken) {
        if (!result.isCompleted) {
          result.complete(PhoneChallenge(phone: phone, verificationId: verificationId, resendToken: resendToken));
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    return result.future;
  }

  @override
  Future<void> confirmCode(PhoneChallenge challenge, String code) async {
    try {
      await _auth.signInWithCredential(
        PhoneAuthProvider.credential(verificationId: challenge.verificationId, smsCode: code),
      );
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  static AuthFailure _map(FirebaseAuthException e) => switch (e.code) {
        'invalid-phone-number' || 'missing-phone-number' => AuthFailure(AuthFailureKind.invalidNumber, e.message),
        'invalid-verification-code' || 'missing-verification-code' => AuthFailure(AuthFailureKind.invalidCode, e.message),
        'session-expired' || 'code-expired' || 'invalid-verification-id' => AuthFailure(AuthFailureKind.codeExpired, e.message),
        'too-many-requests' || 'quota-exceeded' => AuthFailure(AuthFailureKind.tooManyRequests, e.message),
        'network-request-failed' => AuthFailure(AuthFailureKind.network, e.message),
        _ => AuthFailure(AuthFailureKind.unknown, e.message ?? e.code),
      };
}

/// Local development without Firebase: any 6-digit code signs in, except 000000, which
/// behaves like a wrong code. The API must run with AUTH_DEV_BYPASS=true.
class DevAuthRepository implements AuthRepository {
  DevAuthRepository([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'dev_auth_phone';
  static const wrongCode = '000000';
  String? _phone;
  bool _loaded = false;

  Future<String?> _current() async {
    if (!_loaded) {
      _phone = await _storage.read(key: _key);
      _loaded = true;
    }
    return _phone;
  }

  @override
  Future<bool> hasCredentials() async => await _current() != null;

  @override
  Future<String?> token({bool forceRefresh = false}) async {
    final phone = await _current();
    return phone == null ? null : 'dev:$phone';
  }

  @override
  Future<PhoneChallenge> sendCode(String phone, {PhoneChallenge? resendOf, void Function()? onAutoVerified}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return PhoneChallenge(phone: phone, verificationId: 'dev');
  }

  @override
  Future<void> confirmCode(PhoneChallenge challenge, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (code == wrongCode) throw const AuthFailure(AuthFailureKind.invalidCode);
    _phone = challenge.phone;
    _loaded = true;
    await _storage.write(key: _key, value: challenge.phone);
  }

  @override
  Future<void> signOut() async {
    _phone = null;
    _loaded = true;
    await _storage.delete(key: _key);
  }
}
