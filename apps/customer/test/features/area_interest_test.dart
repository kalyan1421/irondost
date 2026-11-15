import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/addresses/address_args.dart';
import 'package:irondost_customer/features/addresses/address_form_screen.dart';
import 'package:irondost_customer/features/addresses/address_repository.dart';
import 'package:irondost_customer/features/addresses/location_service.dart';
import 'package:irondost_customer/features/addresses/map_pin_screen.dart';
import 'package:irondost_customer/features/addresses/place.dart';
import 'package:irondost_customer/features/area_interest/area_interest.dart';
import 'package:irondost_customer/features/area_interest/tell_me_card.dart';
import 'package:irondost_customer/features/auth/session.dart';
import 'package:irondost_customer/features/home/home_screen.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';

import '../helpers.dart';

/// "Tell me when you're here": the repository answers as told, and remembers what it was asked.
class FakeAreaInterestRepository implements AreaInterestRepository {
  final registered = <String>[];
  final failures = <ApiFailure>[];
  Completer<void>? hold;

  @override
  Future<AreaInterestDto> register(String addressId) async {
    registered.add(addressId);
    if (hold != null) await hold!.future;
    if (failures.isNotEmpty) throw failures.removeAt(0);
    return AreaInterestDto(id: 'ai-${registered.length}', pincode: '500032', locality: 'Gachibowli', createdAt: DateTime.utc(2026, 11, 17));
  }
}

/// A customer who signed in with Google and has no mobile number on the account yet.
class _NoNumberSession extends SessionController {
  @override
  Future<Session> build() async => const SignedIn(Profile(id: 'g1', name: 'Gina', email: 'gina@example.com', isComplete: true));
}

/// Saves addresses the way the API does outside the area: not serviceable.
class _OutsideAddresses extends FakeAddressRepository {
  _OutsideAddresses() {
    areaServiceable = false;
  }

  @override
  Future<AddressDto> create(CreateAddressDto dto) async {
    created.add(dto);
    final saved = testAddress(id: 'new-${created.length}', label: dto.label, isPrimary: dto.isPrimary, street: dto.street, area: dto.area ?? '', serviceable: false);
    addresses.add(saved);
    return saved;
  }
}

ApiFailure _rejected(String code) => ApiFailure(ApiFailureKind.rejected, statusCode: 400, code: code);

void main() {
  group('the request', () {
    late FakeAreaInterestRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = FakeAreaInterestRepository();
      container = ProviderContainer(overrides: [areaInterestRepositoryProvider.overrideWithValue(repo)]);
      addTearDown(container.dispose);
    });

    TellMeController controller([String id = 'a1']) => container.read(tellMeProvider(id).notifier);
    TellMeState state([String id = 'a1']) => container.read(tellMeProvider(id));

    test('sends only the saved address, and is done once it is recorded', () async {
      container.listen(tellMeProvider('a1'), (_, _) {});
      expect(state().status, TellMeStatus.idle);
      expect(await controller().send(), isTrue);
      expect(repo.registered, ['a1']);
      expect(state().done, isTrue);
      expect(state().problem, isNull);
    });

    test('a double tap is one request', () async {
      container.listen(tellMeProvider('a1'), (_, _) {});
      repo.hold = Completer<void>();
      final first = controller().send();
      expect(state().sending, isTrue);
      expect(await controller().send(), isFalse);
      repo.hold!.complete();
      await first;
      expect(repo.registered, ['a1']);
    });

    test('each address has its own request', () async {
      container.listen(tellMeProvider('a1'), (_, _) {});
      container.listen(tellMeProvider('a2'), (_, _) {});
      await controller('a1').send();
      expect(state('a1').done, isTrue);
      expect(state('a2').status, TellMeStatus.idle);
    });

    test('says what went wrong in terms of what the customer can do, and a retry can succeed', () async {
      container.listen(tellMeProvider('a1'), (_, _) {});
      final cases = <(ApiFailure, TellMeProblem)>[
        (const ApiFailure(ApiFailureKind.offline), TellMeProblem.offline),
        (const ApiFailure(ApiFailureKind.timeout), TellMeProblem.offline),
        (_rejected('PHONE_REQUIRED'), TellMeProblem.phoneRequired),
        (_rejected('ADDRESS_SERVICEABLE'), TellMeProblem.nowServed),
        (const ApiFailure(ApiFailureKind.server, statusCode: 500), TellMeProblem.failed),
      ];
      for (final (failure, problem) in cases) {
        repo.failures.add(failure);
        expect(await controller().send(), isFalse, reason: '$failure');
        expect(state().status, TellMeStatus.failed);
        expect(state().problem, problem, reason: '$failure');
      }
      expect(await controller().send(), isTrue);
      expect(state().problem, isNull, reason: 'a retry that works clears the message');
    });

    test('the consent names the number when there is one, and what it is for', () {
      expect(tellMeConsent(place: 'Gachibowli', phone: '+91 98765 43210'), contains('the number you signed in with, +91\u00A098765\u00A043210'));
      expect(tellMeConsent(place: 'Gachibowli', phone: '+91 98765 43210'), contains('when we start picking up from Gachibowli'));
      expect(tellMeConsent(place: 'Gachibowli', phone: '+91 98765 43210'), endsWith('Nothing else.'));
      expect(tellMeConsent(place: 'Gachibowli'), contains('mobile number on your account'));
    });
  });

  group('the button', () {
    late FakeAreaInterestRepository repo;

    Future<void> pump(WidgetTester tester, {SessionController Function()? session, double textScale = 1}) async {
      tester.view
        ..physicalSize = const Size(390 * 3, 844 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      repo = FakeAreaInterestRepository();
      final router = testRouter(
        {
          // Home shows it inside a list, so it can scroll at large text.
          '/': () => const Scaffold(body: SingleChildScrollView(padding: EdgeInsets.all(20), child: TellMeWhenHere(addressId: 'a1', place: 'Gachibowli'))),
          Routes.addPhone: () => const Text('ADD PHONE PAGE'),
        },
        initial: '/',
      );
      await tester.pumpWidget(
        themedRouter(
          router,
          textScale: textScale,
          overrides: [
            areaInterestRepositoryProvider.overrideWithValue(repo),
            sessionProvider.overrideWith(session ?? SignedInSession.new),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('asks in plain words, naming the signed-in number, before anything is sent', (tester) async {
      await pump(tester);
      expect(find.text("Tell me when you're here"), findsOneWidget);
      expect(
        find.text("We'll use the number you signed in with, +91\u00A098765\u00A043210, to get in touch when we start picking up from Gachibowli. Nothing else."),
        findsOneWidget,
      );
      expect(repo.registered, isEmpty);
    });

    testWidgets('one tap sends the request and says thanks, with no button left to press again', (tester) async {
      await pump(tester);
      await tester.tap(find.text("Tell me when you're here"));
      await tester.pumpAndSettle();

      expect(repo.registered, ['a1']);
      expect(find.text("Thanks. We'll get in touch when we start picking up from Gachibowli."), findsOneWidget);
      expect(find.text("Tell me when you're here"), findsNothing);
    });

    testWidgets('shows progress while the request is out, and a second tap sends nothing more', (tester) async {
      await pump(tester);
      repo.hold = Completer<void>();
      await tester.tap(find.text("Tell me when you're here"));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text("Tell me when you're here"), findsNothing, reason: 'the label gives way to the spinner');

      repo.hold!.complete();
      await tester.pumpAndSettle();
      expect(repo.registered, hasLength(1));
    });

    testWidgets('offline: says so, keeps the button, and the next tap works', (tester) async {
      await pump(tester);
      repo.failures.add(const ApiFailure(ApiFailureKind.offline));
      await tester.tap(find.text("Tell me when you're here"));
      await tester.pumpAndSettle();
      expect(find.text("You're offline. Check your connection and try again."), findsOneWidget);
      expect(find.text("Tell me when you're here"), findsOneWidget);

      await tester.tap(find.text("Tell me when you're here"));
      await tester.pumpAndSettle();
      expect(find.textContaining("Thanks. We'll get in touch"), findsOneWidget);
      expect(find.text("You're offline. Check your connection and try again."), findsNothing);
    });

    testWidgets('another failure says something went wrong and lets them try again', (tester) async {
      await pump(tester);
      repo.failures.add(const ApiFailure(ApiFailureKind.server, statusCode: 500));
      await tester.tap(find.text("Tell me when you're here"));
      await tester.pumpAndSettle();
      expect(find.text("We couldn't save that. Please try again."), findsOneWidget);
    });

    testWidgets('a customer with no mobile number is asked to add one first, and nothing is sent', (tester) async {
      await pump(tester, session: _NoNumberSession.new);
      expect(find.text("Tell me when you're here"), findsNothing);
      expect(find.text('Add your mobile number'), findsOneWidget);
      expect(find.textContaining('We need a mobile number to reach you'), findsOneWidget);

      await tester.tap(find.text('Add your mobile number'));
      await tester.pumpAndSettle();
      expect(find.text('ADD PHONE PAGE'), findsOneWidget);
      expect(repo.registered, isEmpty);
    });

    testWidgets('reads at 200% text without overflowing', (tester) async {
      await pump(tester, textScale: 2);
      repo.failures.add(const ApiFailure(ApiFailureKind.offline));
      await tester.tap(find.text("Tell me when you're here"));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('the "not in your area yet" screen', () {
    const gachibowli = Place(
      latitude: 17.4401,
      longitude: 78.3489,
      street: 'ISB Road',
      area: 'Gachibowli',
      city: 'Hyderabad',
      state: 'Telangana',
      pincode: '500032',
    );
    late _OutsideAddresses addresses;
    late FakeAreaInterestRepository interest;

    Future<GoRouter> pump(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(390 * 3, 1500 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      addresses = _OutsideAddresses();
      interest = FakeAreaInterestRepository();
      final router = testRouter(
        {
          Routes.addressPin: () => const MapPinScreen(args: PinArgs(initial: gachibowli, onboarding: true)),
          Routes.setupDetails: () => Consumer(
                builder: (context, ref, _) {
                  final args = GoRouterState.of(context).extra! as FormArgs;
                  return AddressFormScreen(args: args);
                },
              ),
        },
        initial: Routes.addressPin,
      );
      await tester.pumpWidget(
        themedRouter(
          router,
          overrides: [
            addressRepositoryProvider.overrideWithValue(addresses),
            areaInterestRepositoryProvider.overrideWithValue(interest),
            locationServiceProvider.overrideWithValue(FakeLocation()),
            sessionProvider.overrideWith(SignedInSession.new),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('keeps Change location and Save for later, and adds Tell me when you are here with the consent line', (tester) async {
      await pump(tester);
      expect(find.text("We're not in Gachibowli yet"), findsOneWidget);
      expect(find.text('Change location'), findsOneWidget);
      expect(find.text("Tell me when you're here"), findsOneWidget);
      expect(find.text('Save for later'), findsOneWidget);
      expect(
        find.text("We'll use the number you signed in with, +91\u00A098765\u00A043210, to get in touch when we start picking up from Gachibowli. Nothing else."),
        findsOneWidget,
      );
      expect(interest.registered, isEmpty, reason: 'the address is not saved yet, so nothing is asked');
    });

    testWidgets('Tell me carries on to the address details, repeats the consent, and saving asks to be told', (tester) async {
      await pump(tester);
      await tester.tap(find.text("Tell me when you're here"));
      await tester.pumpAndSettle();

      expect(find.text('Address details'), findsOneWidget);
      expect(find.textContaining("We're not in Gachibowli yet. We'll use the number you signed in with"), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '12');
      await tester.tap(find.text('Save address'));
      await tester.pumpAndSettle();

      expect(addresses.created, hasLength(1));
      expect(interest.registered, ['new-1'], reason: 'the saved address, nothing typed by the client');
      expect(find.text("Address saved. We'll get in touch when we start picking up from Gachibowli."), findsOneWidget);
    });

    testWidgets('Save for later saves the address and asks for nothing', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Save for later'));
      await tester.pumpAndSettle();
      expect(find.textContaining("We'll use the number you signed in with"), findsNothing);

      await tester.enterText(find.byType(TextField).first, '12');
      await tester.tap(find.text('Save address'));
      await tester.pumpAndSettle();

      expect(addresses.created, hasLength(1));
      expect(interest.registered, isEmpty);
    });

    testWidgets('when the request fails the address is still saved, and the customer is told how to try again', (tester) async {
      await pump(tester);
      interest.failures.add(const ApiFailure(ApiFailureKind.offline));
      await tester.tap(find.text("Tell me when you're here"));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '12');
      await tester.tap(find.text('Save address'));
      await tester.pumpAndSettle();

      expect(addresses.created, hasLength(1));
      expect(find.textContaining("Address saved. You're offline. Check your connection and try again. You can ask again from Home."), findsOneWidget);
    });
  });

  group('Home, with the saved address outside the area', () {
    late FakeAreaInterestRepository interest;

    Future<void> pump(WidgetTester tester, {List<AddressDto>? addresses}) async {
      tester.view
        ..physicalSize = const Size(390 * 2, 1800 * 2)
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      interest = FakeAreaInterestRepository();
      final router = testRouter({Routes.home: () => const HomeScreen()}, initial: Routes.home);
      await tester.pumpWidget(
        themedRouter(
          router,
          overrides: [
            ...await basketOverrides(),
            addressRepositoryProvider.overrideWithValue(FakeAddressRepository(addresses ?? [testAddress(serviceable: false)])),
            orderRepositoryProvider.overrideWithValue(FakeOrderRepository()),
            areaInterestRepositoryProvider.overrideWithValue(interest),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('says we are not there yet, keeps Change address, and offers to tell them', (tester) async {
      await pump(tester);
      expect(find.text('We’re not in Banjara Hills yet'), findsOneWidget);
      expect(find.text('Change address'), findsOneWidget);
      expect(find.text("Tell me when you're here"), findsOneWidget);
      expect(find.textContaining('We\'ll use the number you signed in with, +91\u00A098765\u00A043210'), findsOneWidget);
    });

    testWidgets('one tap asks about the selected saved address and Home then says thanks', (tester) async {
      await pump(tester);
      await tester.tap(find.text("Tell me when you're here"));
      await tester.pumpAndSettle();
      expect(interest.registered, ['a1']);
      expect(find.text("Thanks. We'll get in touch when we start picking up from Banjara Hills."), findsOneWidget);
      expect(find.text("Tell me when you're here"), findsNothing);
    });

    testWidgets('offers nothing when the address is served', (tester) async {
      await pump(tester, addresses: [testAddress()]);
      expect(find.textContaining('We’re not in'), findsNothing);
      expect(find.text("Tell me when you're here"), findsNothing);
    });
  });
}
