import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../core/money.dart';
import '../../core/slots.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/alert_sheet.dart';
import '../../design/widgets/choice_card.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/id_text_field.dart';
import '../../design/widgets/state_view.dart';
import '../../design/widgets/surfaces.dart';
import '../../design/widgets/review_row.dart';
import '../schedule/schedule_screen.dart';
import '../addresses/addresses_controller.dart';
import '../addresses/addresses_screen.dart';
import '../basket/basket.dart';
import '../basket/quote.dart';
import '../basket/quote_bill.dart';
import '../payment/payment_flow.dart';
import '../schedule/schedule.dart';
import 'checkout.dart';

/// Checkout: where from, when, how to pay, and the bill. One tap places the order; online payment
/// then opens Razorpay, cash on delivery goes straight to the confirmation.
class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  Future<void> _place(
    BuildContext context,
    WidgetRef ref,
    Schedule schedule,
    AddressDto address,
  ) async {
    final order = await ref
        .read(checkoutProvider.notifier)
        .place(schedule: schedule, address: address);
    if (order == null || !context.mounted) return;
    await continueAfterPlacing(context, ref, order);
  }

  /// Explains what went wrong and sends the customer where it can be fixed.
  Future<void> _explain(
    BuildContext context,
    WidgetRef ref,
    CheckoutProblem problem,
  ) async {
    // Offline and unexpected failures stay as the line above the button until the next attempt.
    if (problem != CheckoutProblem.offline && problem != CheckoutProblem.failed) {
      ref.read(checkoutProvider.notifier).dismissProblem();
    }
    switch (problem) {
      case CheckoutProblem.slotClosed:
        final change = await showIdAlert(
          context,
          icon: LucideIcons.clock,
          title: 'That time just closed',
          body: "That pickup or delivery time isn't available any more. Pick another time. Your basket and code are kept, and you haven't been charged.",
          primaryLabel: 'Pick another time',
          secondaryLabel: 'Close',
        );
        if (change == true && context.mounted) context.pop();
      case CheckoutProblem.notServiceable:
        final change = await showIdAlert(
          context,
          icon: LucideIcons.mapPinOff,
          title: "We don't pick up from here yet",
          body: 'Choose another address to book. You have not been charged.',
          primaryLabel: 'Choose another address',
          secondaryLabel: 'Close',
        );
        if (change == true && context.mounted) await showAddressPicker(context);
      case CheckoutProblem.itemsChanged:
        await showIdAlert(
          context,
          icon: LucideIcons.shirt,
          title: 'Some items are no longer available',
          body: "We've taken them out of your basket. Have a look before you book. You haven't been charged.",
          primaryLabel: 'Review basket',
        );
        if (context.mounted) {
          context.pop();
          context.pop();
        }
      case CheckoutProblem.basketChanged:
        await showIdAlert(
          context,
          icon: LucideIcons.badgePercent,
          title: 'Your basket changed',
          body: "A price or code isn't the same as before. Have a look at your basket. You haven't been charged.",
          primaryLabel: 'Review basket',
        );
        if (context.mounted) {
          context.pop();
          context.pop();
        }
      case CheckoutProblem.paused:
        await showIdAlert(
          context,
          icon: LucideIcons.circleAlert,
          title: 'Your account is paused',
          body: "We can't take new orders right now. Please contact IronDost support.",
          primaryLabel: 'OK',
          tone: StateTone.danger,
        );
      case CheckoutProblem.offline || CheckoutProblem.failed:
        // Shown inline above the button; nothing to ask.
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(checkoutProvider.select((s) => s.problem), (prev, next) {
      if (next != null && next != prev) _explain(context, ref, next);
    });

    final basket = ref.watch(basketProvider);
    final schedule = ref.watch(scheduleProvider).value;
    final address = ref.watch(selectedAddressProvider);
    final quote = ref.watch(quoteProvider);
    final checkout = ref.watch(checkoutProvider);
    final q = quote.value;
    final quoting = quote.isLoading;

    final appBar = AppBar(
      leading: BackButton(
        onPressed: () =>
            context.canPop() ? context.pop() : context.go(Routes.home),
      ),
      title: Text('Checkout', style: context.text.titleLg),
    );

    if (basket.isEmpty && !checkout.placing) {
      return Scaffold(
        appBar: appBar,
        body: StateView(
          icon: LucideIcons.shoppingBag,
          title: 'Your basket is empty',
          body: 'Add something to book a pickup.',
          primary: IdButton(
            label: 'Choose items',
            onPressed: () => context.go(Routes.book),
          ),
        ),
      );
    }
    if (schedule == null || !schedule.isComplete || address == null) {
      return Scaffold(
        appBar: appBar,
        body: StateView(
          icon: LucideIcons.clock,
          title: 'Choose a pickup time first',
          body: "We'll show your address, bill and payment options after that.",
          primary: IdButton(
            label: 'Choose pickup time',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(Routes.home),
          ),
        ),
      );
    }

    final servable = address.serviceable;
    final total = q?.totalPaise;
    final canPlace =
        servable &&
        q != null &&
        q.canPlaceOrder &&
        !quoting &&
        !checkout.placing;
    final online = checkout.method == PaymentMethod.online;

    return Scaffold(
      appBar: appBar,
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          IdSpace.s5,
          IdSpace.s5,
          IdSpace.s5,
          IdSpace.s6,
        ),
        children: [
          _Where(address: address, schedule: schedule),
          if (!servable) ...[
            const SizedBox(height: IdSpace.s3),
            _NotServed(address: address),
          ],
          const SizedBox(height: IdSpace.s6),
          const _Note(),
          const SizedBox(height: IdSpace.s6),
          Semantics(
            header: true,
            child: Text('Pay with', style: context.text.titleLg),
          ),
          const SizedBox(height: IdSpace.s3),
          ChoiceCard(
            icon: LucideIcons.smartphone,
            title: 'Pay online',
            description: 'UPI, cards and netbanking',
            selected: online,
            onTap: () => ref
                .read(checkoutProvider.notifier)
                .chooseMethod(PaymentMethod.online),
          ),
          const SizedBox(height: IdSpace.s2),
          ChoiceCard(
            icon: LucideIcons.banknote,
            title: 'Cash on delivery',
            description: 'Pay the partner when your clothes come back',
            selected: !online,
            onTap: () => ref
                .read(checkoutProvider.notifier)
                .chooseMethod(PaymentMethod.cod),
          ),
          const SizedBox(height: IdSpace.s6),
          if (quote.hasError && !quoting)
            _QuoteFailure(onRetry: () => ref.invalidate(quoteProvider))
          else
            QuoteBill(quote: q, loading: quoting, pieces: basket.count),
        ],
      ),
      bottomNavigationBar: _Footer(
        online: online,
        totalPaise: total,
        placing: checkout.placing,
        enabled: canPlace,
        offline: checkout.problem == CheckoutProblem.offline,
        failed: checkout.problem == CheckoutProblem.failed,
        onPlace: () => _place(context, ref, schedule, address),
      ),
    );
  }
}

class _Where extends ConsumerWidget {
  const _Where({required this.address, required this.schedule});
  final AddressDto address;
  final Schedule schedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.text;
    void changePickup() => context.canPop() ? context.pop() : context.go(Routes.schedule);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ReviewRow(label: 'Pickup address', value: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(address.label, style: t.title), Text([address.formatted, if(address.landmark?.isNotEmpty ?? false) address.landmark!].join(' · '), style: t.body)]), action: IdButton.text(label: 'Change', onPressed: () => showAddressPicker(context))),
      ReviewRow(label: 'Pickup', value: Text(slotSummary(schedule.pickup!, today: schedule.today), style: t.body), action: IdButton.text(label: 'Change', onPressed: changePickup)),
      ReviewRow(label: 'Delivery', value: Text(slotSummary(schedule.delivery!, today: schedule.today), style: t.body), action: IdButton.text(label: 'Change', onPressed: () => showDeliverySheet(context))),
    ]);
  }
}


/// Quick phrases for the note. Only things that are about the pickup, never promises about how the
/// clothes are handled: care requests are typed in the customer's own words.
const _noteSuggestions = [
  'Call before arriving',
  'Leave with security',
  "Don't ring the bell",
];

/// An optional note for the pickup. It is sent as the order's `instructions` and shown to staff on
/// the order page.
class _Note extends ConsumerStatefulWidget {
  const _Note();

  @override
  ConsumerState<_Note> createState() => _NoteState();
}

class _NoteState extends ConsumerState<_Note> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(checkoutProvider).instructions,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Adds [phrase] after what is already typed, unless it is already there or would not fit.
  void _add(String phrase) {
    final text = _controller.text.trim();
    if (text.contains(phrase)) return;
    final separator = text.isEmpty ? '' : (text.endsWith('.') ? ' ' : '. ');
    final next = '$text$separator$phrase';
    if (next.length > instructionsMaxLength) return;
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    ref.read(checkoutProvider.notifier).setInstructions(next);
  }

  @override
  Widget build(BuildContext context) {
    final placing = ref.watch(checkoutProvider.select((s) => s.placing));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IdTextField(
          label: 'Note for your pickup (optional)',
          hint: 'e.g. Call before arriving',
          help: 'IronDost sees this with your order.',
          controller: _controller,
          enabled: !placing,
          minLines: 2,
          maxLines: 4,
          maxLength: instructionsMaxLength,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onChanged: ref.read(checkoutProvider.notifier).setInstructions,
        ),
        const SizedBox(height: IdSpace.s2),
        Wrap(
          spacing: IdSpace.s2,
          runSpacing: IdSpace.s2,
          children: [
            for (final phrase in _noteSuggestions)
              _Suggestion(
                label: phrase,
                onTap: placing ? null : () => _add(phrase),
              ),
          ],
        ),
      ],
    );
  }
}

/// A neutral outlined control that adds a phrase to the note. At least 48 dp tall, never a filled
/// primary: the one filled button on this screen is Pay or Place order.
class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: 'Add "$label" to the note',
      excludeSemantics: true,
      enabled: onTap != null,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(IdRadius.md),
          side: BorderSide(color: c.borderStrong),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(IdRadius.md),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: IdSize.touchTarget),
            // widthFactor 1: centre the label vertically in the 48 dp target without stretching
            // the chip to the full row.
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: IdSpace.s3,
                  vertical: IdSpace.s2,
                ),
                // No leading icon: with one, the first two phrases are a few dp too wide to share
                // a row at 390 dp, and the note would push the payment choice off the first screen.
                child: Text(
                  label,
                  style: context.text.label.copyWith(color: c.primary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotServed extends StatelessWidget {
  const _NotServed({required this.address});
  final AddressDto address;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.warningSoft,
          borderRadius: BorderRadius.circular(IdRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.mapPinOff, size: IdSize.iconMd, color: c.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "We don't pick up from ${address.area ?? address.city} yet. Choose another address to book.",
                style: t.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteFailure extends StatelessWidget {
  const _QuoteFailure({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IdCard(
      child: Row(
        children: [
          Icon(LucideIcons.circleAlert, color: c.danger),
          const SizedBox(width: IdSpace.s3),
          Expanded(
            child: Text(
              "Couldn't work out the total. Check your connection.",
              style: context.text.body,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.online,
    required this.totalPaise,
    required this.placing,
    required this.enabled,
    required this.offline,
    required this.failed,
    required this.onPlace,
  });

  final bool online;
  final num? totalPaise;
  final bool placing;
  final bool enabled;
  final bool offline;
  final bool failed;
  final VoidCallback onPlace;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final amount = totalPaise == null ? '' : ' ${rupees(totalPaise!)}';
    final label = online ? 'Pay$amount' : 'Place order$amount';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            IdSpace.s5,
            IdSpace.s3,
            IdSpace.s5,
            IdSpace.s3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (offline || failed) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    offline
                        ? "You're offline. Nothing was charged. Check your connection and try again."
                        : "Couldn't place your order. Nothing was charged. Please try again.",
                    style: t.caption.copyWith(color: c.danger),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: IdSpace.s2),
              ],
              IdButton(
                label: label,
                expand: true,
                loading: placing,
                onPressed: enabled ? onPlace : null,
              ),
              const SizedBox(height: IdSpace.s2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    online ? LucideIcons.shieldCheck : LucideIcons.banknote,
                    size: IdSize.iconSm,
                    color: c.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      online
                          ? 'Secure payment by Razorpay'
                          : 'You pay in cash when your clothes are delivered',
                      style: t.caption.copyWith(color: c.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
