import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_client.dart';
import '../push/device_registrar.dart';
import 'auth_repository.dart';

/// The signed-in customer, as the app needs them.
class Profile {
  const Profile({required this.id, required this.phone, this.name, this.email, required this.isComplete});

  factory Profile.fromUser(UserDto u) =>
      Profile(id: u.id, phone: u.phone, name: u.name, email: u.email, isComplete: u.isProfileComplete);
  factory Profile.fromMe(MeDto u) =>
      Profile(id: u.id, phone: u.phone, name: u.name, email: u.email, isComplete: u.isProfileComplete);

  final String id;

  /// E.164, e.g. +919876543210.
  final String phone;
  final String? name;
  final String? email;
  final bool isComplete;

  String get firstName => (name ?? '').trim().split(RegExp(r'\s+')).first;

  String get initials {
    final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }
}

sealed class Session {
  const Session();
}

class SignedOut extends Session {
  const SignedOut();
}

class SignedIn extends Session {
  const SignedIn(this.profile);
  final Profile profile;
}

/// The account exists but staff have disabled it (`ACCOUNT_DISABLED`).
class AccountPaused extends Session {
  const AccountPaused();
}

/// A staff or partner number tried the customer app (`WRONG_APP`).
class WrongApp extends Session {
  const WrongApp();
}

final sessionProvider = AsyncNotifierProvider<SessionController, Session>(SessionController.new);

/// Who is signed in. Errors (offline, server down) surface as AsyncError so the app can show
/// the right screen and retry.
class SessionController extends AsyncNotifier<Session> {
  @override
  Future<Session> build() async {
    final auth = ref.watch(authRepositoryProvider);
    if (!await auth.hasCredentials()) return const SignedOut();
    return _start();
  }

  Future<Session> _start() async {
    final api = ref.read(apiProvider);
    try {
      final user = await api.auth.authControllerSession(body: const StartSessionDto(app: ClientApp.customer));
      // Push registration must never block or fail sign-in.
      unawaited(ref.read(deviceRegistrarProvider).register());
      return SignedIn(Profile.fromUser(user));
    } catch (error) {
      final failure = ApiFailure.from(error);
      switch (failure.code) {
        case 'ACCOUNT_DISABLED':
          return const AccountPaused();
        case 'WRONG_APP':
          await ref.read(authRepositoryProvider).signOut();
          return const WrongApp();
      }
      if (failure.kind == ApiFailureKind.unauthorized) {
        await ref.read(authRepositoryProvider).signOut();
        return const SignedOut();
      }
      throw failure;
    }
  }

  /// Call after the SMS code is confirmed.
  Future<void> signedIn() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_start);
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> saveProfile({required String name, String? email}) async {
    final me = await ref.read(apiProvider).me.usersControllerUpdate(
          body: UpdateMeDto(name: name, email: (email == null || email.isEmpty) ? null : email),
        );
    state = AsyncData(SignedIn(Profile.fromMe(me)));
  }

  Future<void> signOut() async {
    await ref.read(deviceRegistrarProvider).unregister();
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(SignedOut());
  }
}
