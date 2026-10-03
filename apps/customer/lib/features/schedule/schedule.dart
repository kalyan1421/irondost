import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class ScheduleChoiceController extends Notifier<ScheduleChoice> {
  @override
  ScheduleChoice build() => const ScheduleChoice();

  /// Another day: the earliest open window that day is used until one is tapped.
  void pickDate(String date) => state = ScheduleChoice(pickupDate: date);

  /// Another pickup window; delivery goes back to the earliest after it.
  void pickPickup(SlotOptionDto option) => state = ScheduleChoice(pickupDate: option.date, pickup: slotKey(option));

  void pickDelivery(SlotOptionDto option) => state = ScheduleChoice(pickupDate: state.pickupDate, pickup: state.pickup, delivery: slotKey(option));

  /// After an order is placed.
  void clear() => state = const ScheduleChoice();
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
final scheduleProvider = Provider.autoDispose<AsyncValue<Schedule>>((ref) {
  final choice = ref.watch(scheduleChoiceProvider);
  final slots = ref.watch(pickupSlotsProvider);
  if (!slots.hasValue) {
    return slots.hasError ? AsyncError(slots.error!, slots.stackTrace ?? StackTrace.empty) : const AsyncLoading();
  }
  final all = slots.requireValue;
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
});
