import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/account/help_screen.dart';
import 'package:irondost_customer/features/orders/order_detail_screen.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/startup/startup.dart';
import 'package:irondost_customer/features/support/support.dart';

import '../helpers.dart';

const _config = PublicConfigDto(
  appName: 'IronDost',
  supportPhone: '+91 90632 90012',
  supportEmail: 'help@irondost.test',
  minOrderPaise: 0,
  deliveryFeePaise: 0,
  freeDeliveryAbovePaise: null,
  minTurnaroundHours: 20,
  maxAdvanceDays: 30,
  slots: [],
);

void main() {
  group('the WhatsApp link', () {
    test('uses the number with its country code and the message with spaces kept', () {
      expect(
        Support.whatsappUri('+91 90632 90012', message: 'Order ID001046: ').toString(),
        'https://wa.me/919063290012?text=Order%20ID001046%3A%20',
      );
      expect(Support.whatsappUri('9063290012').toString(), 'https://wa.me/919063290012');
      expect(Support.whatsappUri('09063290012').toString(), 'https://wa.me/919063290012');
    });

    test('quotes the order number when there is one', () {
      expect(Support.whatsappMessage(orderNumber: 'ID001046'), 'Order ID001046: ');
      expect(Support.whatsappMessage(), 'Hi IronDost, ');
    });
  });

  group('Chat on WhatsApp', () {
    late List<Uri> launched;
    var opens = true;

    Future<GoRouter> pump(WidgetTester tester, String initial, {Object? extra}) async {
      tester.view
        ..physicalSize = const Size(390 * 3, 1400 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      launched = [];
      final orders = FakeOrderRepository()..orders['o-1'] = testOrder();
      final router = GoRouter(
        initialLocation: initial,
        initialExtra: extra,
        routes: [
          GoRoute(path: Routes.help, builder: (_, _) => const HelpScreen()),
          GoRoute(
            path: Routes.orderDetail,
            builder: (_, s) => OrderDetailScreen(orderId: s.pathParameters['id']!, initial: s.extra as OrderDto?),
          ),
          GoRoute(path: Routes.account, builder: (_, _) => const Text('account')),
        ],
      );
      await tester.pumpWidget(
        themedRouter(
          router,
          overrides: [
            ...await basketOverrides(),
            orderRepositoryProvider.overrideWithValue(orders),
            startupProvider.overrideWith((ref) async => const Startup(config: _config, installedVersion: '2.1.0')),
            supportLauncherProvider.overrideWithValue((uri) async {
              launched.add(uri);
              return opens;
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    setUp(() => opens = true);

    testWidgets('Help offers WhatsApp first, to the support number', (tester) async {
      await pump(tester, Routes.help);
      expect(find.text('Chat on WhatsApp'), findsOneWidget);
      await tester.tap(find.text('Chat on WhatsApp'));
      await tester.pumpAndSettle();
      expect(launched.single.toString(), 'https://wa.me/919063290012?text=Hi%20IronDost%2C%20');
    });

    testWidgets('an order opens a chat that starts with its number', (tester) async {
      await pump(tester, Routes.order('o-1'), extra: testOrder());
      final row = find.text('Chat on WhatsApp');
      await tester.scrollUntilVisible(row, 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(launched.single.host, 'wa.me');
      expect(launched.single.queryParameters['text'], 'Order ID001046: ');
    });

    testWidgets("the order's help sheet offers WhatsApp too", (tester) async {
      await pump(tester, Routes.order('o-1'), extra: testOrder());
      await tester.tap(find.byTooltip('Get help with this order'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, 'Chat on WhatsApp').last);
      await tester.pumpAndSettle();
      expect(launched.single.queryParameters['text'], 'Order ID001046: ');
    });

    testWidgets('without WhatsApp, the number can be copied', (tester) async {
      opens = false;
      await pump(tester, Routes.help);
      await tester.tap(find.text('Chat on WhatsApp'));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't open WhatsApp"), findsOneWidget);
      expect(find.text('+919063290012'), findsOneWidget);
    });
  });
}
