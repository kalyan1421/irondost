import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/design/widgets/address_card.dart';
import 'package:irondost_customer/features/addresses/address_args.dart';
import 'package:irondost_customer/features/addresses/address_form_screen.dart';
import 'package:irondost_customer/features/addresses/address_repository.dart';
import 'package:irondost_customer/features/addresses/addresses_controller.dart';
import 'package:irondost_customer/features/auth/session.dart';

import '../helpers.dart';

const _complete = AddressDraft(latitude: 17.4126, longitude: 78.4482, street: 'Road No. 12', area: 'Banjara Hills', city: 'Hyderabad', state: 'Telangana', pincode: '500034');

void main() {
  late FakeAddressRepository repo;

  Future<void> pumpForm(WidgetTester tester, FormArgs args, {List<AddressDto> existing = const []}) async {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    repo = FakeAddressRepository(existing);
    await tester.pumpWidget(
      themed(
        AddressFormScreen(args: args),
        overrides: [
          addressRepositoryProvider.overrideWithValue(repo),
          sessionProvider.overrideWith(SignedInSession.new),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('asks for the flat number before saving', (tester) async {
    await pumpForm(tester, const FormArgs(draft: _complete, onboarding: true));
    await tester.tap(find.text('Save address'));
    await tester.pump();
    expect(find.text('Enter your flat or house number.'), findsOneWidget);
    expect(repo.created, isEmpty);
  });

  testWidgets('saves the first address as the default, with trimmed details', (tester) async {
    await pumpForm(tester, const FormArgs(draft: _complete, onboarding: true));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), ' 302 ');
    await tester.enterText(fields.at(1), 'Sai Residency');
    await tester.enterText(fields.at(2), '');
    await tester.tap(find.text('Save address'));
    await tester.pumpAndSettle();

    final dto = repo.created.single;
    expect(dto.houseNo, '302');
    expect(dto.building, 'Sai Residency');
    expect(dto.landmark, isNull, reason: 'blank optional fields are not sent');
    expect(dto.street, 'Road No. 12');
    expect(dto.pincode, '500034');
    expect(dto.label, 'Home');
    expect(dto.isPrimary, isTrue);
    expect(dto.latitude, 17.4126);
  });

  testWidgets('asks for what the geocoder could not read', (tester) async {
    await pumpForm(tester, const FormArgs(draft: AddressDraft(latitude: 17.4, longitude: 78.4, city: 'Hyderabad', state: 'Telangana'), onboarding: true));
    expect(find.text("We couldn't read the full address. Fill in what's missing."), findsOneWidget);
    expect(find.text('Street or road'), findsOneWidget);
    expect(find.text('PIN code'), findsOneWidget);
    expect(find.text('City'), findsNothing);

    await tester.enterText(find.byType(TextField).at(0), '12');
    await tester.tap(find.text('Save address'));
    await tester.pump();
    expect(find.text('Enter your street or road.'), findsOneWidget);
    expect(find.text('Enter a 6-digit PIN code.'), findsOneWidget);
    expect(repo.created, isEmpty);
  });

  testWidgets('"Other" needs a name', (tester) async {
    await pumpForm(tester, const FormArgs(draft: _complete, onboarding: true));
    await tester.enterText(find.byType(TextField).at(0), '12');
    await tester.tap(find.text('Other'));
    await tester.pump();
    await tester.tap(find.text('Save address'));
    await tester.pump();
    expect(find.text('Give this address a name, like Parents.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'e.g. Parents'), 'Parents');
    await tester.tap(find.text('Save address'));
    await tester.pumpAndSettle();
    expect(repo.created.single.label, 'Parents');
  });

  testWidgets('a second address is not the default unless chosen', (tester) async {
    await pumpForm(tester, const FormArgs(draft: _complete, onboarding: true), existing: [testAddress()]);
    await tester.enterText(find.byType(TextField).at(0), '12');
    await tester.tap(find.text('Save address'));
    await tester.pumpAndSettle();
    expect(repo.created.single.isPrimary, isFalse);
  });

  testWidgets('editing prefills the saved address and sends its label', (tester) async {
    final saved = testAddress(label: 'Work', isPrimary: false);
    await pumpForm(
      tester,
      FormArgs(draft: AddressDraft.fromAddress(saved), existingId: saved.id, onboarding: true),
      existing: [testAddress(id: 'a0'), saved],
    );
    expect(find.text('Edit address'), findsOneWidget);
    expect(find.widgetWithText(TextField, '302'), findsOneWidget);
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    final dto = repo.updated[saved.id]!;
    expect(dto.label, 'Work');
    expect(dto.houseNo, '302');
  });

  testWidgets('address card marks out-of-area addresses and the default', (tester) async {
    await tester.pumpWidget(
      themed(
        Scaffold(
          body: Column(
            children: [
              AddressCard(address: testAddress(), selected: true),
              AddressCard(address: testAddress(id: 'a2', label: 'Parents', isPrimary: false, serviceable: false), selected: false),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Default'), findsOneWidget);
    expect(find.text('Not in our area yet'), findsOneWidget);
  });

  test('the selected address is the chosen one, else the primary', () async {
    final repo = FakeAddressRepository([testAddress(), testAddress(id: 'a2', label: 'Work', isPrimary: false)]);
    final container = ProviderContainer(overrides: [addressRepositoryProvider.overrideWithValue(repo), sessionProvider.overrideWith(SignedInSession.new)]);
    addTearDown(container.dispose);
    await container.read(sessionProvider.future);
    await container.read(addressesProvider.future);
    expect(container.read(selectedAddressProvider)?.id, 'a1');
    container.read(selectedAddressIdProvider.notifier).select('a2');
    expect(container.read(selectedAddressProvider)?.label, 'Work');
    container.read(selectedAddressIdProvider.notifier).select('deleted');
    expect(container.read(selectedAddressProvider)?.id, 'a1', reason: 'falls back to the default');
  });
}
