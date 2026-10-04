import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/env.dart';
import '../../app/routes.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import 'address_args.dart';
import 'location_service.dart';
import 'map_pin_controller.dart';
import 'pin_map.dart';
import 'place.dart';

/// Step 2 of setup, and "Add new address" later: put the pin on the pickup spot.
///
/// With a Maps key the customer moves a map under a fixed pin. Without one (or with location off)
/// they search for the address or use their current location; the rest of the flow is the same.
class MapPinScreen extends ConsumerStatefulWidget {
  const MapPinScreen({super.key, this.args = const PinArgs()});

  final PinArgs args;

  @override
  ConsumerState<MapPinScreen> createState() => _MapPinScreenState();
}

class _MapPinScreenState extends ConsumerState<MapPinScreen> {
  final _map = PinMapController();

  bool get _onboarding => widget.args.onboarding;

  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(() async {
        final controller = ref.read(mapPinProvider.notifier);
        final initial = widget.args.initial;
        if (initial != null) {
          await controller.start(initial);
        } else {
          await _useMyLocation();
        }
      }),
    );
  }

  Future<void> _useMyLocation() async {
    final place = await ref.read(mapPinProvider.notifier).useCurrentLocation();
    if (place != null && mounted) {
      await _map.moveTo(place.latitude, place.longitude);
    }
  }

  Future<void> _search() async {
    final place = await context.push<Place>(Routes.addressSearch);
    if (place == null || !mounted) return;
    await ref.read(mapPinProvider.notifier).choose(place);
    await _map.moveTo(place.latitude, place.longitude);
  }

  void _confirm(Place place) {
    if (widget.args.mode == PinMode.changeLocation) {
      context.pop(place);
      return;
    }
    final args = FormArgs(
      draft: AddressDraft.fromPlace(place),
      onboarding: _onboarding,
      returnTo: widget.args.returnTo,
    );
    unawaited(
      context.push(
        _onboarding ? Routes.setupDetails : Routes.addressDetails,
        extra: args,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapPinProvider);
    final c = context.colors;
    final initial = widget.args.initial;

    if (!AppEnv.mapsEnabled) {
      return Scaffold(
        backgroundColor: c.surface,
        appBar: AppBar(
          title: const Text('Pickup address'),
          automaticallyImplyLeading: !_onboarding,
        ),
        body: ListView(
          padding: const EdgeInsets.only(top: IdSpace.s4),
          children: [
            _Sheet(
              state: state,
              onboarding: _onboarding,
              onUseLocation: _useMyLocation,
              onSearch: _search,
              onConfirm: _confirm,
              onOpenSettings: () =>
                  ref.read(locationServiceProvider).openSettings(state.access),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: PinMap(
                    controller: _map,
                    initialLatitude: initial?.latitude,
                    initialLongitude: initial?.longitude,
                    onMoved: (lat, lng) =>
                        ref.read(mapPinProvider.notifier).pinMoved(lat, lng),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      IdSpace.s2,
                      IdSpace.s1,
                      IdSpace.s4,
                      0,
                    ),
                    child: Row(
                      children: [
                        if (!_onboarding)
                          Material(
                            color: c.surface,
                            shape: const CircleBorder(),
                            elevation: 3,
                            child: IconButton(
                              icon: const Icon(LucideIcons.arrowLeft),
                              tooltip: 'Back',
                              onPressed: context.pop,
                            ),
                          )
                        else
                          const SizedBox(width: IdSpace.s2),
                        const SizedBox(width: IdSpace.s2),
                        Expanded(child: _SearchField(onTap: _search)),
                      ],
                    ),
                  ),
                ),
                if (AppEnv.mapsEnabled)
                  Positioned(
                    right: IdSpace.s4,
                    bottom: IdSpace.s4,
                    child: Material(
                      color: c.surface,
                      shape: const CircleBorder(),
                      elevation: 3,
                      child: IconButton(
                        icon: state.locating
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(LucideIcons.locate, color: c.primary),
                        tooltip: 'Use my current location',
                        onPressed: state.locating ? null : _useMyLocation,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.6,
            ),
            child: SingleChildScrollView(
              child: _Sheet(
                state: state,
                onboarding: _onboarding,
                onUseLocation: _useMyLocation,
                onSearch: _search,
                onConfirm: _confirm,
                onOpenSettings: () => ref
                    .read(locationServiceProvider)
                    .openSettings(state.access),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: 'Search for a place',
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        elevation: 3,
        borderRadius: BorderRadius.circular(IdRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(IdRadius.md),
          onTap: onTap,
          child: SizedBox(
            height: IdSize.inputHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.search,
                    size: IdSize.iconMd,
                    color: c.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search area, street or building',
                      style: context.text.bodyLg.copyWith(color: c.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.state,
    required this.onboarding,
    required this.onUseLocation,
    required this.onSearch,
    required this.onConfirm,
    required this.onOpenSettings,
  });

  final MapPinState state;
  final bool onboarding;
  final VoidCallback onUseLocation;
  final VoidCallback onSearch;
  final void Function(Place) onConfirm;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(IdRadius.xl),
        ),
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            IdSpace.s5,
            IdSpace.s3,
            IdSpace.s5,
            IdSpace.s4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSize(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 160),
                alignment: Alignment.topCenter,
                child: _content(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    final place = state.place;
    final step = onboarding ? 'Step 2 of 2 · Pickup address' : 'Pickup address';

    if (place == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(step, style: t.caption.copyWith(color: c.textMuted)),
          const SizedBox(height: IdSpace.s1),
          Semantics(
            header: true,
            child: Text(
              state.resolving || state.locating
                  ? 'Finding you…'
                  : 'Where should we pick up?',
              style: t.titleLg,
            ),
          ),
          const SizedBox(height: IdSpace.s2),
          if (state.locationBlocked)
            _Notice(
              icon: LucideIcons.mapPinOff,
              tone: c.warningSoft,
              iconColor: c.warning,
              text: switch (state.access) {
                LocationAccess.serviceOff =>
                  'Location services are off on this phone.',
                LocationAccess.deniedForever =>
                  'Location is blocked for IronDost in Settings.',
                _ => 'Location is off, so search for your address instead.',
              },
              action: state.access == LocationAccess.denied
                  ? 'Try again'
                  : 'Turn on',
              onAction: state.access == LocationAccess.denied
                  ? onUseLocation
                  : onOpenSettings,
            )
          else
            Text(
              'Search for your address or use your current location.',
              style: t.body.copyWith(color: c.textMuted),
            ),
          const SizedBox(height: IdSpace.s4),
          IdButton(
            label: 'Search address',
            icon: LucideIcons.search,
            expand: true,
            onPressed: onSearch,
          ),
          if (!state.locationBlocked) ...[
            const SizedBox(height: IdSpace.s2),
            IdButton.outline(
              label: 'Use my current location',
              icon: LucideIcons.locate,
              expand: true,
              loading: state.locating,
              onPressed: onUseLocation,
            ),
          ],
        ],
      );
    }

    if (state.outsideArea) {
      final where = place.area ?? place.city ?? 'this area';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c.warningSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.mapPinOff, color: c.warning),
              ),
              const SizedBox(width: IdSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text("We're not in $where yet", style: t.titleLg),
                    ),
                    const SizedBox(height: IdSpace.s1),
                    Text(
                      [
                        place.title,
                        place.subtitle,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: t.body.copyWith(color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: IdSpace.s3),
          Text(
            "We can't pick up from here yet. Choose another location to book a pickup. You can still save this address for later.",
            style: t.bodyLg,
          ),
          const SizedBox(height: IdSpace.s4),
          IdButton(label: 'Change location', expand: true, onPressed: onSearch),
          const SizedBox(height: IdSpace.s1),
          IdButton.text(
            label: 'Save for later',
            expand: true,
            onPressed: () => onConfirm(place),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(step, style: t.caption.copyWith(color: c.textMuted)),
        const SizedBox(height: IdSpace.s1),
        Semantics(header: true, child: Text(place.title, style: t.titleLg)),
        if (place.subtitle.isNotEmpty)
          Text(place.subtitle, style: t.body.copyWith(color: c.textMuted)),
        const SizedBox(height: IdSpace.s3),
        _Notice(
          icon: LucideIcons.mapPin,
          tone: c.primarySoft,
          iconColor: c.onPrimarySoft,
          text: AppEnv.mapsEnabled
              ? 'Move the map so the pin sits on your building.'
              : 'Not the right place? Search again to change it.',
        ),
        const SizedBox(height: IdSpace.s4),
        IdButton(
          label: 'Confirm location',
          expand: true,
          loading: state.resolving,
          onPressed: () => onConfirm(place),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.tone,
    required this.iconColor,
    required this.text,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final Color tone;
  final Color iconColor;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        action == null ? 12 : 6,
        action == null ? 14 : 6,
        action == null ? 12 : 6,
      ),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(IdRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: IdSize.iconMd, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: context.text.body)),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}
