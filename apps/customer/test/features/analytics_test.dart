import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/app/links.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/addresses/address_repository.dart';
import 'package:irondost_customer/features/addresses/addresses_controller.dart';
import 'package:irondost_customer/features/analytics/analytics.dart';
import 'package:irondost_customer/features/basket/basket.dart';
import 'package:irondost_customer/features/checkout/checkout.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/orders/orders_list.dart';
import 'package:irondost_customer/features/schedule/schedule.dart';

import '../helpers.dart';

void main() {
  group('install referrer', () {
    test('reads src and c, or the utm names the website sends', () {
      expect(parseReferrer('src=ig&c=diwali'), (src: 'ig', campaign: 'diwali'));
      expect(parseReferrer('utm_source=bag&utm_medium=get_page&utm_campaign=lbnagar'), (src: 'bag', campaign: 'lbnagar'));
      expect(parseReferrer('utm_source=google-play&utm_medium=organic'), (src: 'google-play', campaign: null));
      expect(parseReferrer(null), (src: null, campaign: null));
      expect(parseReferrer(''), (src: null, campaign: null));
    });
  });

  group('the funnel', () {
    late RecordingAnalytics analytics;
    late FakeOrderRepository orders;
    var referrerReads = 0;

    Future<ProviderContainer> container({String? referrer, Map<String, Object> saved = const {}}) async {
      analytics = RecordingAnalytics();
      orders = FakeOrderRepository();
      referrerReads = 0;
      final c = ProviderContainer(
        overrides: [
          ...await basketOverrides(saved: saved),
          analyticsSinkProvider.overrideWithValue(analytics),
          addressRepositoryProvider.overrideWithValue(FakeAddressRepository()),
          orderRepositoryProvider.overrideWithValue(orders),
          installReferrerReaderProvider.overrideWithValue(() async {
            referrerReads++;
            return referrer;
          }),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('app_open every start; the install referrer once, as user properties', () async {
      final c = await container(referrer: 'utm_source=ig&utm_campaign=diwali');
      await c.read(appOpenAnalyticsProvider.future);
      expect(analytics.names, [Funnel.appOpen]);
      expect(analytics.properties, {'src': 'ig', 'c': 'diwali'});
      expect(referrerReads, 1);

      c.invalidate(appOpenAnalyticsProvider);
      await c.read(appOpenAnalyticsProvider.future);
      expect(analytics.names, [Funnel.appOpen, Funnel.appOpen]);
      expect(referrerReads, 1);
    });

    test('a referral install keeps the code for checkout', () async {
      final c = await container(referrer: 'utm_source=ref&utm_medium=get_page&utm_campaign=ravi50');
      await c.read(appOpenAnalyticsProvider.future);
      expect(c.read(referralCodeProvider), 'RAVI50');
    });

    test('address_saved when an address is added', () async {
      final c = await container();
      await c.read(addressesProvider.future);
      await c.read(addressesProvider.notifier).add(const CreateAddressDto(houseNo: '2', street: 'Main Rd', city: 'Hyderabad', state: 'Telangana', pincode: '500074'));
      expect(analytics.names, [Funnel.addressSaved]);
    });

    test('basket_started only for the first piece in an empty basket', () async {
      final c = await container();
      final basket = c.read(basketProvider.notifier);
      basket.add('shirt');
      basket.add('shirt');
      basket.add('trouser');
      expect(analytics.names, [Funnel.basketStarted]);
      basket.clear();
      basket.replaceWith({'shirt': 2});
      expect(analytics.names, [Funnel.basketStarted, Funnel.basketStarted]);
    });

    test('slot_picked when a pickup window is chosen for a booking, not for a reschedule', () async {
      final c = await container();
      c.read(scheduleChoiceProvider.notifier).pickPickup(testSlot('2026-12-01', TimeSlot.morning));
      expect(analytics.events.single.$1, Funnel.slotPicked);
      expect(analytics.events.single.$2, {'slot': 'MORNING', 'date': '2026-12-01'});
    });

    test('order_placed, and second_order when it is the second', () async {
      final c = await container();
      orders.listed.add(testOrder(id: 'o-0', status: OrderStatus.delivered));
      c.listen(ordersListProvider(Scope.active), (_, _) {});
      c.listen(ordersListProvider(Scope.past), (_, _) {});
      await c.read(ordersListProvider(Scope.active).future);
      await c.read(ordersListProvider(Scope.past).future);
      c.read(basketProvider.notifier).add('shirt');
      final pickup = testSlot('2026-12-01', TimeSlot.morning);
      final schedule = Schedule(pickupSlots: [pickup], pickupDate: pickup.date, pickup: pickup, delivery: testSlot('2026-12-02', TimeSlot.evening));
      final placed = await c.read(checkoutProvider.notifier).place(schedule: schedule, address: testAddress());
      expect(placed, isNotNull);
      expect(analytics.names, [Funnel.basketStarted, Funnel.orderPlaced, Funnel.secondOrder]);
      expect(analytics.events[1].$2['currency'], 'INR');
    });
  });
}
