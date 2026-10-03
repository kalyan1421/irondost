import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/addresses/address_repository.dart';
import 'package:irondost_customer/features/basket/basket.dart';
import 'package:irondost_customer/features/catalogue/catalogue.dart';
import 'package:irondost_customer/features/checkout/checkout.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/schedule/schedule.dart';

import '../helpers.dart';

void main() {
  late FakeOrderRepository orders;
  late ProviderContainer container;
  late Schedule schedule;
  final address = testAddress();

  Future<void> setUp({Map<String, Object>? saved}) async {
    orders = FakeOrderRepository();
    container = ProviderContainer(
      overrides: [
        ...await basketOverrides(saved: saved ?? {'basket.v1': '{"lines":{"shirt":2,"saree":1},"promoCode":"WELCOME20"}'}),
        scheduleRepositoryProvider.overrideWithValue(FakeScheduleRepository()),
        orderRepositoryProvider.overrideWithValue(orders),
        addressRepositoryProvider.overrideWithValue(FakeAddressRepository([address])),
      ],
    );
    addTearDown(container.dispose);
    await container.read(catalogProvider.future);
    container.read(basketProvider);
    final sub = container.listen(scheduleProvider, (_, _) {});
    addTearDown(sub.close);
    for (var i = 0; i < 10 && !(container.read(scheduleProvider).value?.isComplete ?? false); i++) {
      await Future<void>.delayed(Duration.zero);
    }
    schedule = container.read(scheduleProvider).requireValue;
  }

  CheckoutController checkout() => container.read(checkoutProvider.notifier);

  test('sends the basket, the chosen windows, the address and the payment method', () async {
    await setUp();
    checkout().chooseMethod(PaymentMethod.cod);

    final order = await checkout().place(schedule: schedule, address: address);

    expect(order, isNotNull);
    final (dto, key) = orders.placed.single;
    expect(dto.items.map((i) => (i.catalogItemId, i.quantity)), [('shirt', 2), ('saree', 1)]);
    expect(dto.promoCode, 'WELCOME20');
    expect(dto.pickupDate, testToday);
    expect(dto.pickupSlot, TimeSlot.evening);
    expect(dto.deliveryDate, '2026-10-04');
    expect(dto.deliverySlot, TimeSlot.evening);
    expect(dto.pickupAddressId, address.id);
    expect(dto.paymentMethod, PaymentMethod.cod);
    expect(key, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
  });

  test('a successful order starts the next basket from scratch', () async {
    await setUp();
    container.read(scheduleChoiceProvider.notifier).pickDate('2026-10-05');

    await checkout().place(schedule: schedule, address: address);

    expect(container.read(basketProvider).isEmpty, isTrue);
    expect(container.read(basketProvider).promoCode, isNull);
    expect(container.read(scheduleChoiceProvider).pickupDate, isNull);
    expect(container.read(checkoutProvider).placing, isFalse);
    expect(container.read(checkoutProvider).problem, isNull);
  });

  test('a double tap places one order', () async {
    await setUp();
    orders.hold = Completer<void>();

    final first = checkout().place(schedule: schedule, address: address);
    final second = await checkout().place(schedule: schedule, address: address);
    expect(second, isNull, reason: 'ignored while the first is running');
    expect(container.read(checkoutProvider).placing, isTrue);

    orders.hold!.complete();
    expect(await first, isNotNull);
    expect(orders.placed, hasLength(1));
  });

  test('retrying after a failure reuses the key, so a hidden success cannot become two orders', () async {
    await setUp();
    orders.failures.add(const ApiFailure(ApiFailureKind.timeout));

    expect(await checkout().place(schedule: schedule, address: address), isNull);
    expect(container.read(checkoutProvider).problem, CheckoutProblem.offline);
    expect(container.read(checkoutProvider).placing, isFalse);

    expect(await checkout().place(schedule: schedule, address: address), isNotNull);
    expect(orders.placed, hasLength(2));
    expect(orders.placed[0].$2, orders.placed[1].$2);
  });

  test('changing anything about the request gets a new key', () async {
    await setUp();
    orders.failures.add(const ApiFailure(ApiFailureKind.server));
    await checkout().place(schedule: schedule, address: address);

    checkout().chooseMethod(PaymentMethod.cod);
    await checkout().place(schedule: schedule, address: address);

    expect(orders.placed[0].$2, isNot(orders.placed[1].$2));
  });

  group('what went wrong', () {
    Future<CheckoutProblem?> failWith(ApiFailure failure) async {
      orders.failures.add(failure);
      final order = await checkout().place(schedule: schedule, address: address);
      expect(order, isNull);
      expect(container.read(checkoutProvider).placing, isFalse, reason: 'the button is usable again');
      return container.read(checkoutProvider).problem;
    }

    ApiFailure rejected(String code, {Map<String, Object?>? details}) => ApiFailure(ApiFailureKind.rejected, statusCode: 400, code: code, details: details);

    test('a window that closed', () async {
      await setUp();
      for (final code in ['PICKUP_SLOT_CLOSED', 'PICKUP_TOO_FAR_AHEAD', 'DELIVERY_TOO_SOON', 'DELIVERY_TOO_FAR_AHEAD']) {
        expect(await failWith(rejected(code)), CheckoutProblem.slotClosed, reason: code);
      }
      expect(container.read(basketProvider).isEmpty, isFalse, reason: 'the basket and code are kept');
    });

    test('an address we do not serve', () async {
      await setUp();
      expect(await failWith(rejected('ADDRESS_NOT_SERVICEABLE')), CheckoutProblem.notServiceable);
    });

    test('items that were withdrawn are taken out of the basket', () async {
      await setUp();
      expect(await failWith(rejected('ITEM_UNAVAILABLE', details: {'catalogItemIds': ['saree']})), CheckoutProblem.itemsChanged);
      expect(container.read(basketProvider).lines, {'shirt': 2});
    });

    test('a code or minimum that no longer holds', () async {
      await setUp();
      expect(await failWith(rejected('PROMO_INVALID')), CheckoutProblem.basketChanged);
      expect(await failWith(rejected('BELOW_MIN_ORDER')), CheckoutProblem.basketChanged);
    });

    test('a paused account, no connection, and anything else', () async {
      await setUp();
      expect(await failWith(const ApiFailure(ApiFailureKind.rejected, statusCode: 403, code: 'CUSTOMER_INACTIVE')), CheckoutProblem.paused);
      expect(await failWith(const ApiFailure(ApiFailureKind.offline)), CheckoutProblem.offline);
      expect(await failWith(const ApiFailure(ApiFailureKind.server, statusCode: 500)), CheckoutProblem.failed);
    });

    test('a reused key (the API says the basket differs) starts a fresh attempt next time', () async {
      await setUp();
      await failWith(rejected('IDEMPOTENCY_KEY_REUSED'));
      await checkout().place(schedule: schedule, address: address);
      expect(orders.placed[0].$2, isNot(orders.placed[1].$2));
    });
  });

  test('an empty basket or incomplete schedule is not sent', () async {
    await setUp(saved: {});
    expect(await checkout().place(schedule: schedule, address: address), isNull);
    expect(orders.placed, isEmpty);
    expect(container.read(checkoutProvider).problem, CheckoutProblem.basketChanged);
  });

  test('the payment method can be chosen, but not while an order is being placed', () async {
    await setUp();
    expect(container.read(checkoutProvider).method, PaymentMethod.online);
    checkout().chooseMethod(PaymentMethod.cod);
    expect(container.read(checkoutProvider).method, PaymentMethod.cod);

    orders.hold = Completer<void>();
    final pending = checkout().place(schedule: schedule, address: address);
    checkout().chooseMethod(PaymentMethod.online);
    expect(container.read(checkoutProvider).method, PaymentMethod.cod);
    orders.hold!.complete();
    await pending;
  });
}
