import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/account/account_screen.dart';
import 'package:irondost_customer/features/account/account_repository.dart';
import 'package:irondost_customer/features/account/edit_profile_screen.dart';
import 'package:irondost_customer/features/addresses/address_repository.dart';
import 'package:irondost_customer/features/auth/auth_repository.dart';
import 'package:irondost_customer/features/auth/session.dart';
import 'package:irondost_customer/features/notifications/notifications.dart';
import 'package:irondost_customer/features/push/device_registrar.dart';
import 'package:irondost_customer/features/startup/startup.dart';

import '../helpers.dart';

class _FakeRegistrar implements DeviceRegistrar {
  int unregistered = 0;

  @override
  Future<void> register() async {}

  @override
  Future<void> unregister() async => unregistered++;

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// A signed-in customer whose profile saves are recorded instead of sent.
class _Session extends SignedInSession {
  _Session({this.email, this.saveFailure});
  final String? email;
  final Object? saveFailure;
  final saved = <(String, String?)>[];

  @override
  Future<Session> build() async => SignedIn(Profile(id: 'u1', phone: '+919876543210', name: 'Priya Sharma', email: email, isComplete: true));

  @override
  Future<void> saveProfile({required String name, String? email}) async {
    if (saveFailure != null) throw saveFailure!;
    saved.add((name, email));
    state = AsyncData(SignedIn(Profile(id: 'u1', phone: '+919876543210', name: name, email: email, isComplete: true)));
  }
}

const _config = PublicConfigDto(
  appName: 'IronDost',
  supportPhone: '+919063290012',
  supportEmail: 'help@irondost.test',
  minOrderPaise: 0,
  deliveryFeePaise: 0,
  freeDeliveryAbovePaise: null,
  minTurnaroundHours: 20,
  maxAdvanceDays: 30,
  slots: [],
);

void main() {
  late FakeAuth auth;
  late _FakeRegistrar registrar;
  late FakeAccountRepository account;
  late _Session session;
  late GoRouter router;

  /// The Account tab on a phone, with the pages it opens shown as their paths.
  Future<ProviderContainer> openAccount(WidgetTester tester, {_Session? as}) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    auth = FakeAuth()..signedIn = true;
    registrar = _FakeRegistrar();
    account = FakeAccountRepository();
    session = as ?? _Session();
    router = GoRouter(
      initialLocation: Routes.account,
      routes: [
        GoRoute(path: Routes.account, builder: (_, _) => const AccountScreen()),
        for (final r in [Routes.editProfile, Routes.addresses, Routes.notifications, Routes.help, Routes.legalDoc, Routes.orders])
          GoRoute(path: r, builder: (_, state) => Text('page ${state.uri}')),
      ],
    );
    late ProviderContainer container;
    await tester.pumpWidget(
      themedRouter(
        router,
        overrides: [
          sessionProvider.overrideWith(() => session),
          authRepositoryProvider.overrideWithValue(auth),
          deviceRegistrarProvider.overrideWithValue(registrar),
          accountRepositoryProvider.overrideWithValue(account),
          addressRepositoryProvider.overrideWithValue(FakeAddressRepository([testAddress(), testAddress(id: 'a2', label: 'Work', isPrimary: false)])),
          notificationRepositoryProvider.overrideWithValue(FakeNotificationRepository()..inbox.addAll([testNotification('n1'), testNotification('n2')])),
          startupProvider.overrideWith((ref) async => const Startup(config: _config, installedVersion: '2.0.0')),
        ],
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(tester.element(find.byType(AccountScreen)));
    return container;
  }

  Session sessionOf(ProviderContainer c) => c.read(sessionProvider).requireValue;

  group('the account tab', () {
    testWidgets('shows who is signed in, how many addresses, unread notifications and the version', (tester) async {
      await openAccount(tester);
      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.text('PS'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // saved addresses
      expect(find.text('2 new'), findsOneWidget);
      expect(find.text('IronDost 2.0.0'), findsOneWidget);
    });

    testWidgets('each row opens its page', (tester) async {
      await openAccount(tester);
      final opens = {
        'Saved addresses': Routes.addresses,
        'Notifications': Routes.notifications,
        'Help & support': Routes.help,
        'Terms of service': '/legal/terms',
        'Privacy policy': '/legal/privacy',
        'Cancellation & refunds': '/legal/cancellation',
      };
      for (final MapEntry(:key, :value) in opens.entries) {
        await tester.tap(find.text(key));
        await tester.pumpAndSettle();
        expect(find.text('page $value'), findsOneWidget, reason: key);
        router.pop();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('the pencil opens Edit profile', (tester) async {
      await openAccount(tester);
      await tester.tap(find.byTooltip('Edit profile'));
      await tester.pumpAndSettle();
      expect(find.text('page ${Routes.editProfile}'), findsOneWidget);
    });
  });

  group('logging out', () {
    testWidgets('asks first, and Stay signed in changes nothing', (tester) async {
      final c = await openAccount(tester);
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(find.text('Log out of IronDost?'), findsOneWidget);

      await tester.tap(find.text('Stay signed in'));
      await tester.pumpAndSettle();
      expect(sessionOf(c), isA<SignedIn>());
      expect(auth.signedIn, isTrue);
      expect(registrar.unregistered, 0);
    });

    testWidgets('Log out stops this phone getting push, signs out and ends the session', (tester) async {
      final c = await openAccount(tester);
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Log out')));
      await tester.pumpAndSettle();

      expect(sessionOf(c), isA<SignedOut>());
      expect(auth.signedIn, isFalse);
      expect(registrar.unregistered, 1);
    });
  });

  group('deleting the account', () {
    Future<void> openDelete(WidgetTester tester) async {
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      expect(find.text('Delete your account?'), findsOneWidget);
    }

    Finder inSheet(String text) => find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

    testWidgets('Keep my account closes the sheet and deletes nothing', (tester) async {
      final c = await openAccount(tester);
      await openDelete(tester);
      await tester.tap(find.text('Keep my account'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(account.deleted, 0);
      expect(sessionOf(c), isA<SignedIn>());
    });

    testWidgets('deleting removes the account, then signs this phone out', (tester) async {
      final c = await openAccount(tester);
      await openDelete(tester);
      await tester.tap(inSheet('Delete account'));
      await tester.pumpAndSettle();

      expect(account.deleted, 1);
      expect(sessionOf(c), isA<SignedOut>());
      expect(auth.signedIn, isFalse);
      expect(registrar.unregistered, 0, reason: 'the server already removed the device');
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('orders in progress block it, say how many, and lead to Orders', (tester) async {
      final c = await openAccount(tester);
      account.failure = const ApiFailure(ApiFailureKind.rejected, statusCode: 409, code: 'ACTIVE_ORDERS', details: {'activeOrders': 2});
      await openDelete(tester);
      await tester.tap(inSheet('Delete account'));
      await tester.pumpAndSettle();

      expect(find.text('Finish your orders first'), findsOneWidget);
      expect(find.textContaining('You have 2 orders in progress'), findsOneWidget);
      expect(sessionOf(c), isA<SignedIn>());

      await tester.tap(find.text('View orders'));
      await tester.pumpAndSettle();
      expect(find.text('page ${Routes.orders}'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('one order in progress reads as singular', (tester) async {
      await openAccount(tester);
      account.failure = const ApiFailure(ApiFailureKind.rejected, statusCode: 409, code: 'ACTIVE_ORDERS', details: {'activeOrders': 1});
      await openDelete(tester);
      await tester.tap(inSheet('Delete account'));
      await tester.pumpAndSettle();

      expect(find.textContaining('You have 1 order in progress'), findsOneWidget);
      expect(find.textContaining("once it's delivered or cancelled"), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('offline says the account was not deleted and stays signed in, then can retry', (tester) async {
      final c = await openAccount(tester);
      account.failure = const ApiFailure(ApiFailureKind.offline);
      await openDelete(tester);
      await tester.tap(inSheet('Delete account'));
      await tester.pumpAndSettle();

      expect(find.textContaining("You're offline. Your account has not been deleted"), findsOneWidget);
      expect(sessionOf(c), isA<SignedIn>());

      account.failure = null;
      await tester.tap(inSheet('Delete account'));
      await tester.pumpAndSettle();
      expect(account.deleted, 1);
      expect(sessionOf(c), isA<SignedOut>());
    });

    testWidgets('any other failure leaves the account active', (tester) async {
      final c = await openAccount(tester);
      account.failure = const ApiFailure(ApiFailureKind.server, statusCode: 500);
      await openDelete(tester);
      await tester.tap(inSheet('Delete account'));
      await tester.pumpAndSettle();

      expect(find.textContaining("It's still active"), findsOneWidget);
      expect(sessionOf(c), isA<SignedIn>());
    });
  });

  group('edit profile', () {
    Future<void> openEdit(WidgetTester tester, {_Session? as}) async {
      tester.view
        ..physicalSize = const Size(390 * 3, 844 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      session = as ?? _Session(email: 'priya@example.com');
      final router = testRouter(
        {Routes.account: () => const Scaffold(body: Text('account tab')), Routes.editProfile: () => const EditProfileScreen(), Routes.help: () => const Text('help page')},
        initial: Routes.account,
      );
      await tester.pumpWidget(themedRouter(router, overrides: [sessionProvider.overrideWith(() => session)]));
      await tester.pumpAndSettle();
      // The app always has the session loaded by the time any screen is open.
      await ProviderScope.containerOf(tester.element(find.text('account tab'))).read(sessionProvider.future);
      unawaited(router.push(Routes.editProfile));
      await tester.pumpAndSettle();
    }

    EditableText field(WidgetTester tester, int i) => tester.widgetList<EditableText>(find.byType(EditableText)).elementAt(i);

    testWidgets('starts with the current name and email, and the number is locked', (tester) async {
      await openEdit(tester);
      expect(field(tester, 0).controller.text, 'Priya Sharma');
      expect(field(tester, 1).controller.text, 'priya@example.com');
      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Mobile number, +91 98765 43210, cannot be changed' && w.properties.readOnly == true), findsOneWidget);
    });

    testWidgets('the avatar follows the name as it is typed', (tester) async {
      await openEdit(tester);
      expect(find.text('PS'), findsOneWidget);
      await tester.enterText(find.byType(EditableText).first, 'Arun Kumar Reddy');
      await tester.pump();
      expect(find.text('AR'), findsOneWidget);
    });

    testWidgets('a short name or a bad email is refused beside the field, nothing is sent', (tester) async {
      await openEdit(tester);
      await tester.enterText(find.byType(EditableText).first, 'P');
      await tester.enterText(find.byType(EditableText).at(1), 'not-an-email');
      await tester.tap(find.text('Save changes'));
      await tester.pump();

      expect(find.textContaining('Enter your name'), findsOneWidget);
      expect(find.textContaining('Enter a valid email'), findsOneWidget);
      expect(session.saved, isEmpty);
    });

    testWidgets('saving sends the trimmed values, returns, and says so', (tester) async {
      await openEdit(tester);
      await tester.enterText(find.byType(EditableText).first, '  Priya S  ');
      await tester.enterText(find.byType(EditableText).at(1), '');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(session.saved, [('Priya S', '')]);
      expect(find.text('Profile saved'), findsOneWidget);
      expect(find.text('account tab'), findsOneWidget);
    });

    testWidgets('an offline save keeps the form and says so', (tester) async {
      await openEdit(tester, as: _Session(saveFailure: const ApiFailure(ApiFailureKind.offline)));
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.textContaining("You're offline"), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
    });

    testWidgets('the support link leads to Help', (tester) async {
      await openEdit(tester);
      await tester.tap(find.text('contact support'));
      await tester.pumpAndSettle();
      expect(find.text('help page'), findsOneWidget);
    });
  });
}
