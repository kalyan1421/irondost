import '../analytics/analytics.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/slots.dart';
import '../../data/api_client.dart';

/// Pickup and delivery windows from the API. Which are open (not past, far enough ahead, at least
/// the minimum turnaround after pickup) is the server's call: the app only shows `available`.
abstract class ScheduleRepository {
  Future<List<SlotOptionDto>> pickupSlots();
  Future<List<SlotOptionDto>> deliverySlots(String pickupDate, TimeSlot pickupSlot);
}

class ApiScheduleRepository implements ScheduleRepository {
  ApiScheduleRepository(this._api);
  final IronDostApi _api;

  @override
  Future<List<SlotOptionDto>> pickupSlots() => _guard(() => _api.schedule.schedulingControllerPickupSlots());

  @override
  Future<List<SlotOptionDto>> deliverySlots(String pickupDate, TimeSlot pickupSlot) =>
      _guard(() => _api.schedule.schedulingControllerDeliverySlots(pickupDate: pickupDate, pickupSlot: pickupSlot));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiFailure.from(e);
    }
  }
}

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) => ApiScheduleRepository(ref.watch(apiProvider)));

/// A window, as the API names it: an IST calendar date and a slot.
typedef SlotKey = ({String date, TimeSlot slot});

SlotKey slotKey(SlotOptionDto o) => (date: o.date, slot: o.slot);

final pickupSlotsProvider = FutureProvider.autoDispose<List<SlotOptionDto>>((ref) => ref.watch(scheduleRepositoryProvider).pickupSlots());

final deliverySlotsProvider = FutureProvider.autoDispose.family<List<SlotOptionDto>, SlotKey>(
  (ref, pickup) => ref.watch(scheduleRepositoryProvider).deliverySlots(pickup.date, pickup.slot),
);

/// What the customer has tapped so far. Anything not chosen (or no longer open) falls back to the
/// earliest open window, see [scheduleProvider].
class ScheduleChoice {
  const ScheduleChoice({this.pickupDate, this.pickup, this.delivery});

  /// The date tab being viewed.
  final String? pickupDate;
  final SlotKey? pickup;
  final SlotKey? delivery;
}

final scheduleChoiceProvider = NotifierProvider<ScheduleChoiceController, ScheduleChoice>(ScheduleChoiceController.new);

/// What the picker widgets call when the customer taps. Booking and rescheduling each keep their own state behind it.
abstract interface class SchedulePicks {
  void pickDate(String date);
  void pickPickup(SlotOptionDto option);
  void pickDelivery(SlotOptionDto option);
}

abstract class _PicksController extends Notifier<ScheduleChoice> implements SchedulePicks {
  /// Another day: the earliest open window that day is used until one is tapped.
  @override
  void pickDate(String date) => state = ScheduleChoice(pickupDate: date);

  /// Another pickup window; delivery goes back to the earliest after it.
  @override
  void pickPickup(SlotOptionDto option) => state = ScheduleChoice(pickupDate: option.date, pickup: slotKey(option));

  @override
  void pickDelivery(SlotOptionDto option) => state = ScheduleChoice(pickupDate: state.pickupDate, pickup: state.pickup, delivery: slotKey(option));
}

class ScheduleChoiceController extends _PicksController {
  @override
  ScheduleChoice build() => const ScheduleChoice();

  @override
  void pickPickup(SlotOptionDto option) {
    super.pickPickup(option);
    ref.read(analyticsProvider).log(Funnel.slotPicked, {'slot': option.slot.json ?? '', 'date': option.date});
  }

  /// After an order is placed.
  void clear() => state = const ScheduleChoice();
}

/// The order whose time is being changed, and the windows it has now. A record, so the same order gives the same provider.
typedef RescheduleStart = ({String orderId, SlotKey pickup, SlotKey delivery});

/// Changing one order's time: the picker starts on the windows the order has now, and nothing the customer taps here
/// touches the booking in progress.
final rescheduleChoiceProvider = NotifierProvider.autoDispose.family<RescheduleChoiceController, ScheduleChoice, RescheduleStart>(
  RescheduleChoiceController.new,
);

class RescheduleChoiceController extends _PicksController {
  RescheduleChoiceController(this.start);
  final RescheduleStart start;

  @override
  ScheduleChoice build() => ScheduleChoice(pickupDate: start.pickup.date, pickup: start.pickup, delivery: start.delivery);

  // The delivery the order has is kept whenever it is still allowed after the pickup that was tapped; when it is not, the
  // earliest one that is takes its place (see [buildSchedule]). Going back to the order's own day selects its own window.

  @override
  void pickDate(String date) => state = ScheduleChoice(pickupDate: date, pickup: date == start.pickup.date ? start.pickup : null, delivery: start.delivery);

  @override
  void pickPickup(SlotOptionDto option) => state = ScheduleChoice(pickupDate: option.date, pickup: slotKey(option), delivery: start.delivery);
}

/// The pickup and delivery windows on offer, and which are selected.
class Schedule {
  const Schedule({required this.pickupSlots, required this.pickupDate, this.pickup, this.deliverySlots, this.delivery});

  final List<SlotOptionDto> pickupSlots;

  /// The date tab in view. Empty only when the API listed no windows at all.
  final String pickupDate;
  final SlotOptionDto? pickup;

  /// Null until there is a pickup to deliver after.
  final AsyncValue<List<SlotOptionDto>>? deliverySlots;
  final SlotOptionDto? delivery;

  bool get isEmpty => pickupSlots.isEmpty;

  /// The API's first day is today (IST).
  String? get today => pickupSlots.firstOrNull?.date;

  List<String> get pickupDates => _dates(pickupSlots);

  List<SlotOptionDto> get pickupWindows => [for (final s in pickupSlots) if (s.date == pickupDate) s];

  /// The earliest open pickup anywhere, for "Pick Sat, 7 – 11 AM".
  SlotOptionDto? get earliestPickup => pickupSlots.where((s) => s.available).firstOrNull;

  /// Both windows chosen: ready to continue.
  bool get isComplete => pickup != null && delivery != null;

  /// Whether [delivery] is simply the earliest the API allows.
  bool get deliveryIsEarliest {
    final first = deliverySlots?.value?.where((s) => s.available).firstOrNull;
    return delivery != null && first != null && slotKey(first) == slotKey(delivery!);
  }

  List<String> get deliveryDates => _dates(deliverySlots?.value ?? const []);

  static List<String> _dates(List<SlotOptionDto> slots) => [
        for (final date in <String>{for (final s in slots) s.date}) date,
      ];
}

/// The schedule as it stands: the customer's taps over the API's windows, with defaults filled in.
final scheduleProvider = Provider.autoDispose<AsyncValue<Schedule>>((ref) => buildSchedule(ref, ref.watch(scheduleChoiceProvider)));

/// The same for one order's time change.
final rescheduleScheduleProvider = Provider.autoDispose.family<AsyncValue<Schedule>, RescheduleStart>(
  (ref, start) => buildSchedule(ref, ref.watch(rescheduleChoiceProvider(start)), own: start.pickup),
);

/// [choice] laid over the API's windows: a window that is closed (or no longer allowed after the pickup) is not kept,
/// and whatever was not chosen falls back to the earliest open one. [own] is the pickup window an order being moved already
/// holds: the API counts that order in the window, so it may say "full" for the very window the customer has. It is theirs, so
/// it stays open to choose again (the API does not count a move that keeps the same pickup window).
AsyncValue<Schedule> buildSchedule(Ref ref, ScheduleChoice choice, {SlotKey? own}) {
  final slots = ref.watch(pickupSlotsProvider);
  if (!slots.hasValue) {
    return slots.hasError ? AsyncError(slots.error!, slots.stackTrace ?? StackTrace.empty) : const AsyncLoading();
  }
  final all = [
    for (final s in slots.requireValue)
      if (own != null && s.isFull && slotKey(s) == own)
        SlotOptionDto(date: s.date, slot: s.slot, label: s.label, startsAt: s.startsAt, endsAt: s.endsAt, available: true, reason: null)
      else
        s,
  ];
  if (all.isEmpty) return const AsyncData(Schedule(pickupSlots: [], pickupDate: ''));

  final date = all.any((s) => s.date == choice.pickupDate) ? choice.pickupDate! : all.first.date;
  final onDate = all.where((s) => s.date == date);
  SlotOptionDto? chosen() {
    for (final s in onDate) {
      if (s.available && choice.pickup != null && slotKey(s) == choice.pickup) return s;
    }
    return null;
  }

  final pickup = chosen() ?? onDate.where((s) => s.available).firstOrNull;
  if (pickup == null) return AsyncData(Schedule(pickupSlots: all, pickupDate: date));

  final deliverySlots = ref.watch(deliverySlotsProvider(slotKey(pickup)));
  SlotOptionDto? delivery;
  final options = deliverySlots.value;
  if (options != null) {
    for (final s in options) {
      if (s.available && choice.delivery != null && slotKey(s) == choice.delivery) delivery = s;
    }
    delivery ??= options.where((s) => s.available).firstOrNull;
  }
  return AsyncData(Schedule(pickupSlots: all, pickupDate: date, pickup: pickup, deliverySlots: deliverySlots, delivery: delivery));
}
