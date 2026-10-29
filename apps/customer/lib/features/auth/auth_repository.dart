import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../app/env.dart';
import '../../core/phone.dart';
import '../../firebase_options.dart';

enum AuthFailureKind {
  invalidNumber,
  invalidCode,
  codeExpired,

  /// Firebase's per-number or per-device limit; the customer has to wait.
  tooManyRequests,

  /// The number being added already belongs to another IronDost account.
  phoneInUse,

  /// The customer closed the Google account picker. Not an error worth a message.
  googleCancelled,

  /// Google sign-in is not set up in this build (no OAuth client in the Firebase config), or Google Play services are missing.
  googleUnavailable,
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
/// read the SMS itself and the customer is already signed in (or, for [link], the number is already attached).
///
/// With [link] the code adds the number to the account that is already signed in (a Google customer) instead of signing in.
class PhoneChallenge {
  const PhoneChallenge({
    required this.phone,
    required this.verificationId,
    this.resendToken,
    this.autoVerified = false,
    this.link = false,
  });
  final String phone;
  final String verificationId;
  final int? resendToken;
  final bool autoVerified;
  final bool link;
}

/// Phone-number and Google sign-in. The API only ever sees the resulting ID token.
abstract class AuthRepository {
  /// Whether a previous sign-in is still on this phone.
  Future<bool> hasCredentials();

  /// The bearer token for API calls, or null when signed out.
  Future<String?> token({bool forceRefresh = false});

  /// Sends an SMS code. [onAutoVerified] runs if Android verifies the number without the code.
  /// With [link] the number is verified for the signed-in account instead of signing in.
  Future<PhoneChallenge> sendCode(String phone, {PhoneChallenge? resendOf, void Function()? onAutoVerified, bool link = false});

  /// Signs in, or (for a [PhoneChallenge.link] challenge) attaches the number to the signed-in account.
  Future<void> confirmCode(PhoneChallenge challenge, String code);

  /// Signs in with a Google account. Throws [AuthFailure] when cancelled or not set up.
  Future<void> signInWithGoogle();

  /// Whether the signed-in account already has a verified number attached.
  Future<bool> hasVerifiedPhone();

  /// Detaches the number that was just added, after the API found it belongs to another account, so another can be tried.
  Future<void> unlinkPhone();

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
  Future<PhoneChallenge> sendCode(String phone, {PhoneChallenge? resendOf, void Function()? onAutoVerified, bool link = false}) {
    final result = Completer<PhoneChallenge>();
    _auth.verifyPhoneNumber(
      phoneNumber: IndianPhone.e164(phone),
      forceResendingToken: resendOf?.resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        try {
          await _useCredential(credential, link: link);
          if (!result.isCompleted) {
            result.complete(PhoneChallenge(phone: phone, verificationId: '', autoVerified: true, link: link));
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
          result.complete(PhoneChallenge(phone: phone, verificationId: verificationId, resendToken: resendToken, link: link));
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    return result.future;
  }

  @override
  Future<void> confirmCode(PhoneChallenge challenge, String code) async {
    try {
      await _useCredential(
        PhoneAuthProvider.credential(verificationId: challenge.verificationId, smsCode: code),
        link: challenge.link,
      );
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    }
  }

  /// Signs in with the phone credential, or attaches it to the signed-in (Google) account. After attaching, a fresh ID token
  /// is fetched so the `phone_number` claim is in it when the app next calls the API.
  Future<void> _useCredential(PhoneAuthCredential credential, {required bool link}) async {
    if (!link) {
      await _auth.signInWithCredential(credential);
      return;
    }
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure(AuthFailureKind.unknown, 'Not signed in');
    await user.linkWithCredential(credential);
    await user.getIdToken(true);
  }

  @override
  Future<bool> hasVerifiedPhone() async => (_auth.currentUser?.phoneNumber ?? '').isNotEmpty;

  @override
  Future<void> unlinkPhone() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.unlink(PhoneAuthProvider.PROVIDER_ID);
      await user.getIdToken(true);
    } on FirebaseAuthException {
      // Nothing was linked, or it is gone already.
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    // The iOS SDK ends the app with an exception, not an error, when the OAuth client or the URL scheme is missing, so do not
    // call it until the Firebase config says it is set up. Android reports a normal error instead.
    final options = DefaultFirebaseOptions.currentPlatform;
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    if (isIos && (options.iosClientId ?? '').isEmpty) {
      throw const AuthFailure(AuthFailureKind.googleUnavailable, 'No iOS OAuth client in the Firebase config');
    }
    try {
      final google = GoogleSignIn.instance;
      if (!_googleReady) {
        await google.initialize(clientId: isIos ? options.iosClientId : null);
        _googleReady = true;
      }
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const AuthFailure(AuthFailureKind.googleUnavailable, 'Google returned no ID token');
      await _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
    } on GoogleSignInException catch (e) {
      throw _mapGoogle(e);
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    } on PlatformException catch (e) {
      throw AuthFailure(AuthFailureKind.googleUnavailable, e.message ?? e.code);
    }
  }

  bool _googleReady = false;

  static AuthFailure _mapGoogle(GoogleSignInException e) => switch (e.code) {
        GoogleSignInExceptionCode.canceled => AuthFailure(AuthFailureKind.googleCancelled, e.description),
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError ||
        GoogleSignInExceptionCode.uiUnavailable =>
          AuthFailure(AuthFailureKind.googleUnavailable, e.description),
        GoogleSignInExceptionCode.interrupted => AuthFailure(AuthFailureKind.network, e.description),
        _ => AuthFailure(AuthFailureKind.unknown, e.description),
      };

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } on Object {
        // Signing out of Firebase is what ends the session; Google's own state is a courtesy.
      }
    }
  }

  static AuthFailure _map(FirebaseAuthException e) => switch (e.code) {
        'invalid-phone-number' || 'missing-phone-number' => AuthFailure(AuthFailureKind.invalidNumber, e.message),
        'invalid-verification-code' || 'missing-verification-code' => AuthFailure(AuthFailureKind.invalidCode, e.message),
        'session-expired' || 'code-expired' || 'invalid-verification-id' => AuthFailure(AuthFailureKind.codeExpired, e.message),
        'too-many-requests' || 'quota-exceeded' => AuthFailure(AuthFailureKind.tooManyRequests, e.message),
        'credential-already-in-use' || 'account-exists-with-different-credential' => AuthFailure(AuthFailureKind.phoneInUse, e.message),
        'network-request-failed' => AuthFailure(AuthFailureKind.network, e.message),
        _ => AuthFailure(AuthFailureKind.unknown, e.message ?? e.code),
      };
}

/// Local development without Firebase: any 6-digit code signs in, except 000000, which
/// behaves like a wrong code. "Continue with Google" signs in as [googleEmail], and adding a number to that account works
/// the same way (any code but 000000). The API must run with AUTH_DEV_BYPASS=true.
class DevAuthRepository implements AuthRepository {
  DevAuthRepository([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'dev_auth_phone';
  static const _googleKey = 'dev_auth_google_email';
  static const _googlePhoneKey = 'dev_auth_google_phone';
  static const wrongCode = '000000';

  /// The account "Continue with Google" signs in as in dev mode.
  static const googleEmail = 'dev.customer@example.com';

  String? _phone;
  String? _google;
  String? _googlePhone;
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    _phone = await _storage.read(key: _key);
    _google = await _storage.read(key: _googleKey);
    _googlePhone = await _storage.read(key: _googlePhoneKey);
    _loaded = true;
  }

  @override
  Future<bool> hasCredentials() async {
    await _load();
    return _phone != null || _google != null;
  }

  @override
  Future<String?> token({bool forceRefresh = false}) async {
    await _load();
    if (_google != null) return _googlePhone == null ? 'dev-google:$_google' : 'dev-google:$_google:$_googlePhone';
    return _phone == null ? null : 'dev:$_phone';
  }

  @override
  Future<PhoneChallenge> sendCode(String phone, {PhoneChallenge? resendOf, void Function()? onAutoVerified, bool link = false}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return PhoneChallenge(phone: phone, verificationId: 'dev', link: link);
  }

  @override
  Future<void> confirmCode(PhoneChallenge challenge, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (code == wrongCode) throw const AuthFailure(AuthFailureKind.invalidCode);
    await _load();
    if (challenge.link) {
      _googlePhone = challenge.phone;
      await _storage.write(key: _googlePhoneKey, value: challenge.phone);
      return;
    }
    _phone = challenge.phone;
    _google = null;
    _googlePhone = null;
    await _storage.delete(key: _googleKey);
    await _storage.delete(key: _googlePhoneKey);
    await _storage.write(key: _key, value: challenge.phone);
  }

  @override
  Future<void> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await _load();
    _google = googleEmail;
    _phone = null;
    await _storage.write(key: _googleKey, value: googleEmail);
    await _storage.delete(key: _key);
  }

  @override
  Future<bool> hasVerifiedPhone() async {
    await _load();
    return _googlePhone != null;
  }

  @override
  Future<void> unlinkPhone() async {
    _googlePhone = null;
    await _storage.delete(key: _googlePhoneKey);
  }

  @override
  Future<void> signOut() async {
    _phone = null;
    _google = null;
    _googlePhone = null;
    _loaded = true;
    await _storage.delete(key: _key);
    await _storage.delete(key: _googleKey);
    await _storage.delete(key: _googlePhoneKey);
  }
}
