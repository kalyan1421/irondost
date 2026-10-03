import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/address_card.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/id_text_field.dart';
import 'address_args.dart';
import 'addresses_controller.dart';
import 'place.dart';

const _labels = ['Home', 'Work', 'Other'];

/// Details for one address: flat/house, building, landmark, a label and whether it's the default.
/// Used for new addresses (after the pin) and for editing saved ones.
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, required this.args});

  final FormArgs args;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  late AddressDraft _draft = widget.args.draft;
  late final _houseNo = TextEditingController(text: _draft.houseNo);
  late final _building = TextEditingController(text: _draft.building);
  late final _landmark = TextEditingController(text: _draft.landmark);
  late final _street = TextEditingController(text: _draft.street ?? '');
  late final _city = TextEditingController(text: _draft.city ?? '');
  late final _state = TextEditingController(text: _draft.state ?? '');
  late final _pincode = TextEditingController(text: _draft.pincode ?? '');
  late final _otherLabel = TextEditingController(text: _labels.contains(_draft.label) ? '' : _draft.label);
  late String _choice = _labels.contains(_draft.label) ? _draft.label : 'Other';
  late bool _primary = _draft.isPrimary;
  final _errors = <String, String>{};
  var _saving = false;

  bool get _editing => widget.args.existingId != null;

  /// The geocoder couldn't read these; ask the customer for them.
  bool get _needsStreet => (_draft.street ?? '').trim().length < 2;
  bool get _needsCity => (_draft.city ?? '').trim().length < 2;
  bool get _needsState => (_draft.state ?? '').trim().length < 2;
  bool get _needsPincode => !RegExp(r'^[1-9]\d{5}$').hasMatch(_draft.pincode ?? '');
  bool get _needsAnything => _needsStreet || _needsCity || _needsState || _needsPincode;

  @override
  void dispose() {
    for (final c in [_houseNo, _building, _landmark, _street, _city, _state, _pincode, _otherLabel]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _changeLocation() async {
    if (!_editing) {
      context.pop();
      return;
    }
    final lat = _draft.latitude;
    final lng = _draft.longitude;
    final place = await context.push<Place>(
      Routes.addressPin,
      extra: PinArgs(
        initial: lat == null || lng == null ? null : Place(latitude: lat, longitude: lng, street: _draft.street, area: _draft.area, city: _draft.city, state: _draft.state, pincode: _draft.pincode),
        mode: PinMode.changeLocation,
      ),
    );
    if (place == null || !mounted) return;
    setState(() {
      _draft = _draft.movedTo(place);
      _street.text = _draft.street ?? '';
      _city.text = _draft.city ?? '';
      _state.text = _draft.state ?? '';
      _pincode.text = _draft.pincode ?? '';
    });
  }

  String get _label => _choice == 'Other' ? _otherLabel.text.trim() : _choice;

  bool _validate() {
    _errors.clear();
    if (_houseNo.text.trim().isEmpty) _errors['house'] = 'Enter your flat or house number.';
    if (_needsStreet && _street.text.trim().length < 2) _errors['street'] = 'Enter your street or road.';
    if (_needsCity && _city.text.trim().length < 2) _errors['city'] = 'Enter your city.';
    if (_needsState && _state.text.trim().length < 2) _errors['state'] = 'Enter your state.';
    if (_needsPincode && !RegExp(r'^[1-9]\d{5}$').hasMatch(_pincode.text.trim())) _errors['pincode'] = 'Enter a 6-digit PIN code.';
    if (_choice == 'Other' && _label.isEmpty) _errors['label'] = 'Give this address a name, like Parents.';
    setState(() {});
    return _errors.isEmpty;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final street = _needsStreet ? _street.text.trim() : (_draft.street ?? '').trim();
    final city = _needsCity ? _city.text.trim() : (_draft.city ?? '').trim();
    final state = _needsState ? _state.text.trim() : (_draft.state ?? '').trim();
    final pincode = _needsPincode ? _pincode.text.trim() : (_draft.pincode ?? '').trim();
    String? optional(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

    setState(() => _saving = true);
    try {
      final notifier = ref.read(addressesProvider.notifier);
      // Wait for the list: the first address is always the default.
      final firstAddress = (await ref.read(addressesProvider.future)).isEmpty;
      final AddressDto saved;
      if (_editing) {
        saved = await notifier.edit(
          widget.args.existingId!,
          UpdateAddressDto(
            label: _label,
            houseNo: _houseNo.text.trim(),
            building: optional(_building),
            street: street,
            area: _draft.area,
            landmark: optional(_landmark),
            city: city,
            state: state,
            pincode: pincode,
            latitude: _draft.latitude,
            longitude: _draft.longitude,
            isPrimary: _primary,
          ),
        );
      } else {
        saved = await notifier.add(
          CreateAddressDto(
            label: _label,
            houseNo: _houseNo.text.trim(),
            building: optional(_building),
            street: street,
            area: _draft.area,
            landmark: optional(_landmark),
            city: city,
            state: state,
            pincode: pincode,
            latitude: _draft.latitude,
            longitude: _draft.longitude,
            isPrimary: _primary || firstAddress,
          ),
        );
        ref.read(selectedAddressIdProvider.notifier).select(saved.id);
      }
      if (!mounted) return;
      // First-run setup finishes by itself: with an address saved the router moves on to Home.
      if (!widget.args.onboarding) context.go(widget.args.returnTo ?? Routes.home);
    } catch (e) {
      if (!mounted) return;
      final failure = ApiFailure.from(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failure.isConnectivity
                ? "You're offline. Check your connection and try again."
                : failure.kind == ApiFailureKind.rejected
                    ? "We couldn't save that address. Check the details and try again."
                    : 'Something went wrong. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final c = context.colors;
    final t = context.text;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(IdSpace.s4, 0, IdSpace.s4, IdSpace.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Delete this address?', style: t.headline),
              const SizedBox(height: IdSpace.s2),
              Text('Past orders keep it. You can add it again any time.', style: t.bodyLg.copyWith(color: c.textMuted)),
              const SizedBox(height: IdSpace.s5),
              IdButton.danger(label: 'Delete address', expand: true, onPressed: () => Navigator.pop(sheet, true)),
              const SizedBox(height: IdSpace.s2),
              IdButton.outline(label: 'Keep address', expand: true, onPressed: () => Navigator.pop(sheet, false)),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(addressesProvider.notifier).remove(widget.args.existingId!);
      if (mounted) context.go(widget.args.returnTo ?? Routes.addresses);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("We couldn't delete that address. Try again.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final noAddressesYet = (ref.watch(addressesProvider).value ?? const <AddressDto>[]).isEmpty;
    final lockedPrimary = (noAddressesYet && !_editing) || (_editing && _draft.isPrimary);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), tooltip: 'Back', onPressed: context.pop),
        title: Text(_editing ? 'Edit address' : 'Address details'),
        shape: Border(bottom: BorderSide(color: c.border)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s4, IdSpace.s4, IdSpace.s6),
              children: [
                _Summary(draft: _draft, onChange: _changeLocation),
                const SizedBox(height: IdSpace.s5),
                IdTextField(
                  label: 'Flat or house number',
                  controller: _houseNo,
                  error: _errors['house'],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() => _errors.remove('house')),
                ),
                const SizedBox(height: IdSpace.s5),
                IdTextField(label: 'Building or apartment', controller: _building, textInputAction: TextInputAction.next),
                const SizedBox(height: IdSpace.s5),
                IdTextField(
                  label: 'Landmark (optional)',
                  controller: _landmark,
                  help: 'Helps your partner find you faster.',
                  textInputAction: TextInputAction.next,
                ),
                if (_needsAnything) ...[
                  const SizedBox(height: IdSpace.s6),
                  Text("We couldn't read the full address. Fill in what's missing.", style: t.body.copyWith(color: c.textMuted)),
                  if (_needsStreet) ...[
                    const SizedBox(height: IdSpace.s4),
                    IdTextField(label: 'Street or road', controller: _street, error: _errors['street'], textInputAction: TextInputAction.next),
                  ],
                  if (_needsCity) ...[
                    const SizedBox(height: IdSpace.s4),
                    IdTextField(label: 'City', controller: _city, error: _errors['city'], textInputAction: TextInputAction.next),
                  ],
                  if (_needsState) ...[
                    const SizedBox(height: IdSpace.s4),
                    IdTextField(label: 'State', controller: _state, error: _errors['state'], textInputAction: TextInputAction.next),
                  ],
                  if (_needsPincode) ...[
                    const SizedBox(height: IdSpace.s4),
                    IdTextField(
                      label: 'PIN code',
                      controller: _pincode,
                      error: _errors['pincode'],
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                    ),
                  ],
                ],
                const SizedBox(height: IdSpace.s6),
                Semantics(header: true, child: Text('Save as', style: t.labelSm)),
                const SizedBox(height: IdSpace.s3),
                Wrap(
                  spacing: IdSpace.s2,
                  runSpacing: IdSpace.s2,
                  children: [
                    for (final label in _labels)
                      _LabelChip(
                        label: label,
                        icon: label == 'Other' ? null : addressIcon(label),
                        selected: _choice == label,
                        onTap: () => setState(() {
                          _choice = label;
                          _errors.remove('label');
                        }),
                      ),
                  ],
                ),
                if (_choice == 'Other') ...[
                  const SizedBox(height: IdSpace.s4),
                  IdTextField(
                    label: 'Name this address',
                    controller: _otherLabel,
                    error: _errors['label'],
                    hint: 'e.g. Parents',
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [LengthLimitingTextInputFormatter(30)],
                  ),
                ],
                const SizedBox(height: IdSpace.s6),
                MergeSemantics(
                  child: Row(
                    children: [
                      Expanded(child: Text('Use as my default address', style: t.bodyLg)),
                      Switch(value: _primary || lockedPrimary, onChanged: lockedPrimary ? null : (v) => setState(() => _primary = v)),
                    ],
                  ),
                ),
                if (_editing) ...[
                  const SizedBox(height: IdSpace.s6),
                  IdButton.danger(label: 'Delete address', icon: LucideIcons.trash, expand: true, onPressed: _saving ? null : _delete),
                ],
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(color: c.surface, boxShadow: context.shadows.sheet),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s3, IdSpace.s4, IdSpace.s4),
                child: IdButton(label: _editing ? 'Save changes' : 'Save address', expand: true, loading: _saving, onPressed: _save),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.draft, required this.onChange});

  final AddressDraft draft;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final title = draft.title.isEmpty ? 'Pickup location' : draft.title;
    return Container(
      padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s2, IdSpace.s2, IdSpace.s2),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(IdRadius.lg),
        boxShadow: context.shadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.surfaceSoft, borderRadius: BorderRadius.circular(IdRadius.sm)),
            child: Icon(LucideIcons.mapPin, size: IdSize.iconMd, color: c.primary),
          ),
          const SizedBox(width: IdSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.title),
                if (draft.subtitle.isNotEmpty) Text(draft.subtitle, style: t.body.copyWith(color: c.textMuted)),
              ],
            ),
          ),
          TextButton(onPressed: onChange, child: const Text('Change')),
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.primarySoft : c.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? c.primary : c.borderStrong, width: selected ? 2 : 1)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: IdSize.touchTarget - 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: IdSpace.s4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: IdSize.iconSm, color: selected ? c.onPrimarySoft : c.text), const SizedBox(width: IdSpace.s1)],
                  Text(label, style: context.text.labelSm.copyWith(color: selected ? c.onPrimarySoft : c.text)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
