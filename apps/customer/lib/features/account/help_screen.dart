import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../core/phone.dart';
import '../../design/theme.dart';
import '../../design/widgets/surfaces.dart';
import '../startup/startup.dart';
import '../support/support.dart';
import 'legal_content.dart';

/// "Help and support": call or email, the questions people ask most, and the policies.
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final support = Support.of(ref);
    final hours =
        (ref.watch(startupProvider).value?.config.minTurnaroundHours ?? 20)
            .toInt();

    final faqs = [
      (
        'When will my clothes come back?',
        'You choose an available delivery window at checkout. Delivery slots allow at least $hours hours after pickup.',
      ),
      (
        'Can I change or cancel a pickup?',
        'You can cancel in the app until your clothes are picked up: open the order and tap Cancel order. After pickup, call us. To change the time, cancel and book again.',
      ),
      (
        'What if an item is damaged or missing?',
        "Tell us within 48 hours of delivery. Call or email with your order number and we'll look into it and offer a repair, a replacement or a refund.",
      ),
      (
        'How do refunds work?',
        'Contact support after cancellation or to report a service issue. Approved refunds go back to your original payment method, usually within 7–14 business days.',
      ),
    ];

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(bottom: IdSpace.s3),
      child: Semantics(
        header: true,
        child: Text(text, style: t.labelSm.copyWith(color: c.textMuted)),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.account),
        ),
        title: Text('Help and support', style: t.titleLg),
      ),
      body: ListView(
        padding: const EdgeInsets.all(IdSpace.s5),
        children: [
          heading('Talk to us'),
          IdListGroup(
            children: [
              _ContactRow(
                icon: LucideIcons.phone,
                title: 'Call us',
                detail: IndianPhone.display(support.phone),
                onTap: () => Support.dial(support.phone),
              ),
              if (support.email != null)
                _ContactRow(
                  icon: LucideIcons.mail,
                  title: 'Email us',
                  detail: support.email!,
                  onTap: () => Support.mail(support.email!),
                ),
            ],
          ),
          const SizedBox(height: IdSpace.s5),
          heading('Common questions'),
          IdListGroup(
            children: [
              for (final (i, (q, a)) in faqs.indexed)
                _Faq(question: q, answer: a, initiallyOpen: i == 0),
            ],
          ),
          const SizedBox(height: IdSpace.s5),
          IdListGroup(
            children: [
              IdListRow(
                icon: LegalDoc.cancellation.icon,
                label: 'Cancellation and refunds',
                onTap: () =>
                    context.push(Routes.legal(LegalDoc.cancellation.slug)),
              ),
              IdListRow(
                icon: LegalDoc.terms.icon,
                label: 'Terms of service',
                onTap: () => context.push(Routes.legal(LegalDoc.terms.slug)),
              ),
              IdListRow(
                icon: LegalDoc.privacy.icon,
                label: 'Privacy policy',
                onTap: () => context.push(Routes.legal(LegalDoc.privacy.slug)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: IdSpace.s3,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.surfaceSoft,
                    borderRadius: BorderRadius.circular(IdRadius.sm),
                  ),
                  child: Icon(icon, size: IdSize.iconMd, color: c.primary),
                ),
                const SizedBox(width: IdSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: t.title),
                      Text(detail, style: t.body.copyWith(color: c.textMuted)),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: IdSize.iconSm,
                  color: c.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A question that opens to its answer.
class _Faq extends StatefulWidget {
  const _Faq({
    required this.question,
    required this.answer,
    required this.initiallyOpen,
  });

  final String question;
  final String answer;
  final bool initiallyOpen;

  @override
  State<_Faq> createState() => _FaqState();
}

class _FaqState extends State<_Faq> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      container: true,
      child: InkWell(
        onTap: () => setState(() => _open = !_open),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        expanded: _open,
                        child: Text(widget.question, style: t.title),
                      ),
                    ),
                    const SizedBox(width: IdSpace.s2),
                    Icon(
                      _open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      size: IdSize.iconMd,
                      color: c.textMuted,
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 150),
                  alignment: Alignment.topCenter,
                  child: _open
                      ? Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            widget.answer,
                            style: t.body.copyWith(color: c.textMuted),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
