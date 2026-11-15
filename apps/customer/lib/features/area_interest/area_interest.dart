import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_client.dart';

/// "Tell me when you're here": asks IronDost to get in touch when it starts serving a saved address that is outside the
/// service area. The API reads the place from the saved address and uses the signed-in number, so only the address id goes.
abstract class AreaInterestRepository {
  /// Idempotent: asking again for the same PIN code is the same request.
  Future<AreaInterestDto> register(String addressId);
}

class ApiAreaInterestRepository implements AreaInterestRepository {
  ApiAreaInterestRepository(this._api);
  final IronDostApi _api;

  @override
  Future<AreaInterestDto> register(String addressId) async {
    try {
      return await _api.areaInterest.areaInterestControllerRegister(body: RegisterAreaInterestDto(addressId: addressId));
    } on DioException catch (e) {
      throw ApiFailure.from(e);
    }
  }
}

final areaInterestRepositoryProvider = Provider<AreaInterestRepository>((ref) => ApiAreaInterestRepository(ref.watch(apiProvider)));

/// Why the request did not go through, in terms of what the customer can do.
enum TellMeProblem {
  /// No connection: nothing was sent, trying again is safe.
  offline,

  /// The account has no mobile number to reach them on.
  phoneRequired,

  /// The address is served now (it changed, or the area grew): they can just book.
  nowServed,

  /// Anything else.
  failed,
}

enum TellMeStatus { idle, sending, done, failed }

class TellMeState {
  const TellMeState({this.status = TellMeStatus.idle, this.problem});

  final TellMeStatus status;
  final TellMeProblem? problem;

  bool get sending => status == TellMeStatus.sending;
  bool get done => status == TellMeStatus.done;
}

TellMeProblem tellMeProblemFor(ApiFailure e) {
  if (e.isConnectivity) return TellMeProblem.offline;
  return switch (e.code) {
    'PHONE_REQUIRED' => TellMeProblem.phoneRequired,
    'ADDRESS_SERVICEABLE' => TellMeProblem.nowServed,
    _ => TellMeProblem.failed,
  };
}

/// One address's "tell me when you're here" request. Kept for the session, so Home still says "we'll tell you" after the
/// customer has been to another screen and back.
final tellMeProvider = NotifierProvider.family<TellMeController, TellMeState, String>(TellMeController.new);

class TellMeController extends Notifier<TellMeState> {
  TellMeController(this.addressId);
  final String addressId;

  @override
  TellMeState build() => const TellMeState();

  /// Sends the request. A second call while one is running does nothing, so a double tap is one request.
  Future<bool> send() async {
    if (state.sending) return false;
    state = const TellMeState(status: TellMeStatus.sending);
    try {
      await ref.read(areaInterestRepositoryProvider).register(addressId);
      if (!ref.mounted) return true;
      state = const TellMeState(status: TellMeStatus.done);
      return true;
    } on ApiFailure catch (e) {
      if (ref.mounted) state = TellMeState(status: TellMeStatus.failed, problem: tellMeProblemFor(e));
      return false;
    }
  }
}

/// What the customer reads next to the button and under it, in plain words. The number is bound with no-break spaces, so it
/// is never split across two lines.
String tellMeConsent({required String place, String? phone}) => phone == null
    ? "We'll use the mobile number on your account to get in touch when we start picking up from $place. Nothing else."
    : "We'll use the number you signed in with, ${phone.replaceAll(' ', '\u00A0')}, to get in touch when we start picking up from $place. Nothing else.";

String tellMeProblemText(TellMeProblem problem) => switch (problem) {
      TellMeProblem.offline => "You're offline. Check your connection and try again.",
      TellMeProblem.phoneRequired => 'Add your mobile number first, so we know where to reach you.',
      TellMeProblem.nowServed => 'Good news: we pick up from this address now. You can book a pickup.',
      TellMeProblem.failed => "We couldn't save that. Please try again.",
    };
