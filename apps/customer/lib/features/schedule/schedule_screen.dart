import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../core/phone.dart';
import '../../core/slots.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/slot_picker.dart';
import '../../design/widgets/surfaces.dart';
import '../startup/startup.dart';
import '../support/support.dart';
import 'schedule.dart';

/// "Pickup time": the day and window for collection, and the earliest delivery after ironing
/// (changeable). Closed windows stay listed, dimmed, so it is clear why they can't be picked.
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(scheduleProvider);
    final s = schedule.value;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home)),
        title: Text('Pickup time', style: context.text.titleLg),
      ),
      body: schedule.when(
        loading: () => const _Loading(),
        error: (e, _) => _LoadFailure(offline: ApiFailure.from(e).isConnectivity, onRetry: () => ref.invalidate(pickupSlotsProvider)),
        data: (s) => s.isEmpty ? const _NothingOpen() : _Body(schedule: s),
      ),
      bottomNavigationBar: _Footer(enabled: s?.isComplete ?? false),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.schedule});
  final Schedule schedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.text;
    final c = context.colors;
    final choice = ref.read(scheduleChoiceProvider.notifier);
    final today = schedule.today!;
    final earliest = schedule.earliestPickup;

    return ListView(
      padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s5, IdSpace.s4, IdSpace.s6),
      children: [
        Semantics(header: true, child: Text('When should we collect?', style: t.titleLg)),
        Text('Your partner arrives within the window you pick.', style: t.bodyLg.copyWith(color: c.textMuted)),
        const SizedBox(height: IdSpace.s3),
        DateStrip(
          label: 'Pickup date',
          dates: schedule.pickupDates,
          selected: schedule.pickupDate,
          today: today,
          onSelect: choice.pickDate,
        ),
        const SizedBox(height: IdSpace.s3),
        for (final slot in schedule.pickupWindows) ...[
          SlotTile(
            name: slotName(slot.slot),
            window: slotWindow(slot),
            selected: schedule.pickup != null && slotKey(slot) == slotKey(schedule.pickup!),
            enabled: slot.available,
            onTap: () => choice.pickPickup(slot),
          ),
          const SizedBox(height: IdSpace.s2),
        ],
        if (schedule.pickup == null) ...[
          const SizedBox(height: IdSpace.s2),
          _NoneOpenNotice(day: schedule.pickupDate, today: today, earliest: earliest, onPickEarliest: earliest == null ? null : () => choice.pickPickup(earliest)),
        ],
        if (schedule.pickup != null) ...[
          const SizedBox(height: IdSpace.s6),
          Semantics(header: true, child: Text('Delivery', style: t.titleLg)),
          const SizedBox(height: IdSpace.s3),
          _DeliveryCard(schedule: schedule),
        ],
      ],
    );
  }
}

/// "Today's pickups have closed. The earliest is Sat, 7 – 11 AM." with a button that takes it.
class _NoneOpenNotice extends StatelessWidget {
  const _NoneOpenNotice({required this.day, required this.today, required this.earliest, required this.onPickEarliest});

  final String day;
  final String today;
  final SlotOptionDto? earliest;
  final VoidCallback? onPickEarliest;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final what = day == today ? "Today's pickups have closed." : 'No pickups are open on ${dayLong(day)}.';
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(IdRadius.md)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.clock, size: IdSize.iconMd, color: c.onPrimarySoft),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    earliest == null ? "$what We'll open more times soon. Please check back." : '$what The earliest is ${slotSummary(earliest!, today: today)}.',
                    style: t.body,
                  ),
                ),
              ],
            ),
            if (earliest != null) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: c.surface, foregroundColor: c.onPrimarySoft),
                  onPressed: onPickEarliest,
                  child: Text('Pick ${dayChipTop(earliest!.date, today: today)}, ${slotWindow(earliest!)}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeliveryCard extends ConsumerWidget {
  const _DeliveryCard({required this.schedule});
  final Schedule schedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final options = schedule.deliverySlots;
    final delivery = schedule.delivery;

    if (options == null || options.isLoading && !options.hasValue) {
      return IdCard(
        child: Semantics(
          label: 'Finding delivery times',
          child: ExcludeSemantics(
            child: Row(
              children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: c.surfaceSoft, borderRadius: BorderRadius.circular(IdRadius.sm))),
                const SizedBox(width: IdSpace.s3),
                Container(width: 160, height: 16, decoration: BoxDecoration(color: c.surfaceSoft, borderRadius: BorderRadius.circular(IdRadius.sm))),
              ],
            ),
          ),
        ),
      );
    }
    if (options.hasError && !options.hasValue) {
      return IdCard(
        child: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              Icon(LucideIcons.circleAlert, color: c.danger),
              const SizedBox(width: IdSpace.s3),
              Expanded(child: Text("Couldn't load delivery times.", style: t.body)),
              TextButton(
                onPressed: () => ref.invalidate(deliverySlotsProvider((date: schedule.pickup!.date, slot: schedule.pickup!.slot))),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    if (delivery == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: c.warningSoft, borderRadius: BorderRadius.circular(IdRadius.md)),
        child: Semantics(
          liveRegion: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.circleAlert, size: IdSize.iconMd, color: c.warning),
              const SizedBox(width: 10),
              Expanded(child: Text('No delivery times are open after that pickup. Try another pickup time.', style: t.body)),
            ],
          ),
        ),
      );
    }
    return IdCard(
      padding: const EdgeInsets.symmetric(horizontal: IdSpace.s4, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.surfaceSoft, borderRadius: BorderRadius.circular(IdRadius.sm)),
            child: Icon(LucideIcons.truck, size: IdSize.iconMd, color: c.primary),
          ),
          const SizedBox(width: IdSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slotSummary(delivery, today: schedule.today), style: t.title),
                Text(schedule.deliveryIsEarliest ? 'Earliest after ironing' : 'Your choice', style: t.caption.copyWith(color: c.textMuted)),
              ],
            ),
          ),
          IdButton.text(label: 'Change', onPressed: () => showDeliverySheet(context)),
        ],
      ),
    );
  }
}

/// "Delivery time": any open window after the earliest the ironing allows.
Future<void> showDeliverySheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _DeliverySheet(),
    );

class _DeliverySheet extends ConsumerStatefulWidget {
  const _DeliverySheet();

  @override
  ConsumerState<_DeliverySheet> createState() => _DeliverySheetState();
}

class _DeliverySheetState extends ConsumerState<_DeliverySheet> {
  String? _date;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    final schedule = ref.watch(scheduleProvider).value;
    final slots = schedule?.deliverySlots?.value ?? const <SlotOptionDto>[];
    final dates = schedule?.deliveryDates ?? const <String>[];
    final date = dates.contains(_date) ? _date! : (schedule?.delivery?.date ?? (dates.isEmpty ? '' : dates.first));
    final hours = ref.read(startupProvider).value?.config.minTurnaroundHours;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(IdSpace.s4, 0, IdSpace.s4, IdSpace.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text('Delivery time', style: t.titleLg)),
            Text(
              "Ironing takes about ${hours ?? 20} hours, so earlier windows aren't available.",
              style: t.bodyLg.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: IdSpace.s4),
            if (dates.isNotEmpty)
              DateStrip(
                label: 'Delivery date',
                dates: dates,
                selected: date,
                today: schedule!.today!,
                onSelect: (d) => setState(() => _date = d),
              ),
            const SizedBox(height: IdSpace.s3),
            for (final slot in slots.where((s) => s.date == date)) ...[
              SlotTile(
                name: slotName(slot.slot),
                window: slotWindow(slot),
                selected: schedule?.delivery != null && slotKey(slot) == slotKey(schedule!.delivery!),
                enabled: slot.available,
                closedNote: 'Too soon',
                onTap: () => ref.read(scheduleChoiceProvider.notifier).pickDelivery(slot),
              ),
              const SizedBox(height: IdSpace.s2),
            ],
            const SizedBox(height: IdSpace.s2),
            IdButton(label: 'Done', expand: true, onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.enabled});
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.surface, boxShadow: context.shadows.sheet),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s3, IdSpace.s4, IdSpace.s3),
          child: IdButton(label: 'Continue', expand: true, onPressed: enabled ? () => context.push(Routes.checkout) : null),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget block(double w, double h, {double radius = IdRadius.md}) => Container(width: w, height: h, decoration: BoxDecoration(color: c.surfaceSoft, borderRadius: BorderRadius.circular(radius)));
    return Semantics(
      label: 'Loading pickup times',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.all(IdSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              block(220, 22),
              const SizedBox(height: IdSpace.s4),
              Row(children: [for (var i = 0; i < 4; i++) ...[block(64, 72), const SizedBox(width: IdSpace.s2)]]),
              const SizedBox(height: IdSpace.s4),
              for (var i = 0; i < 3; i++) ...[SizedBox(width: double.infinity, child: block(double.infinity, 64)), const SizedBox(height: IdSpace.s2)],
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.offline, required this.onRetry});
  final bool offline;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return ListView(
      padding: const EdgeInsets.all(IdSpace.s4),
      children: [
        IdCard(
          padding: const EdgeInsets.symmetric(horizontal: IdSpace.s5, vertical: IdSpace.s8),
          child: Semantics(
            liveRegion: true,
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: c.dangerSoft, shape: BoxShape.circle),
                  child: Icon(offline ? LucideIcons.wifiOff : LucideIcons.circleAlert, size: IdSize.iconLg, color: c.danger),
                ),
                const SizedBox(height: IdSpace.s3),
                Text("Couldn't load pickup times", style: t.titleLg),
                const SizedBox(height: IdSpace.s2),
                Text(
                  offline ? "You're offline. Check your connection and try again." : 'Please try again in a moment.',
                  style: t.body.copyWith(color: c.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: IdSpace.s4),
                IdButton.tonal(label: 'Try again', icon: LucideIcons.refreshCw, onPressed: onRetry),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The API listed no windows at all (every day closed).
class _NothingOpen extends ConsumerWidget {
  const _NothingOpen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final phone = Support.of(ref).phone;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(IdSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.clock, size: 52, color: c.textMuted),
            const SizedBox(height: IdSpace.s4),
            Text('No pickup times open right now', style: t.titleLg, textAlign: TextAlign.center),
            const SizedBox(height: IdSpace.s2),
            Text("We'll open more times soon. Call us if you need a pickup today.", style: t.body.copyWith(color: c.textMuted), textAlign: TextAlign.center),
            const SizedBox(height: IdSpace.s4),
            IdButton.outline(label: 'Call ${IndianPhone.display(phone)}', icon: LucideIcons.phone, onPressed: () => Support.dial(phone)),
          ],
        ),
      ),
    );
  }
}
