import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_sheet.dart';
import '../../design/widgets/numbered_steps.dart';
import '../../design/widgets/surfaces.dart';
import '../account/legal_content.dart';
import '../startup/startup.dart';

/// "How it works": what happens to an order, in plain words, from what the Terms of service and the
/// cancellation policy already say.
///
/// This sheet makes no promise of its own. It says nothing about how clothes are ironed (steam, press),
/// quality guarantees or per-service turnaround, because the policies do not. Each line below restates
/// one of [howItWorksSources]; a test fails if the policy text those come from changes, so the two
/// cannot quietly disagree.
Future<void> showHowItWorks(BuildContext context, WidgetRef ref) {
  final hours =
      (ref.read(startupProvider).value?.config.minTurnaroundHours ?? 20)
          .toInt();
  return showIdSheet<void>(
    context,
    builder: (sheet) {
      void openPolicy(LegalDoc doc) {
        Navigator.pop(sheet);
        if (context.mounted) context.push(Routes.legal(doc.slug));
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text('How it works', style: sheet.text.titleLg),
          ),
          const SizedBox(height: IdSpace.s3),
          NumberedSteps(
            steps: [
              (
                'Pickup and count',
                'Your partner collects your clothes and counts them. The bill follows that count.',
              ),
              (
                'We do the work',
                'We iron, wash or dry-clean them as you chose.',
              ),
              (
                'Back to you',
                'A partner brings them back in the window you picked. Delivery takes about $hours hours or more from pickup, depending on the service and our workload. The window is our target, not a guarantee.',
              ),
            ],
          ),
          const SizedBox(height: IdSpace.s5),
          const _Heading('Looking after your clothes'),
          Text(
            'We take reasonable care of your garments.',
            style: sheet.text.body,
          ),
          const SizedBox(height: IdSpace.s2),
          const _Bullets([
            'Tell us about stains, delicate fabrics and expensive embellishments when you hand over your clothes.',
            'Report any damage or missing item within 48 hours of delivery. We will inspect it and offer a repair, a replacement or a refund.',
          ]),
          const SizedBox(height: IdSpace.s5),
          const _Heading('Changing your mind'),
          const _Bullets([
            'Before pickup: cancel free in the app.',
            'After pickup, before ironing starts: call us.',
            "Once ironing has started, the order can't be cancelled or refunded.",
          ]),
          const SizedBox(height: IdSpace.s5),
          IdListGroup(
            children: [
              IdListRow(
                icon: LegalDoc.cancellation.icon,
                label: 'Cancellation and refunds',
                onTap: () => openPolicy(LegalDoc.cancellation),
              ),
              IdListRow(
                icon: LegalDoc.terms.icon,
                label: 'Terms of service',
                onTap: () => openPolicy(LegalDoc.terms),
              ),
            ],
          ),
        ],
      );
    },
  );
}

/// The policy sentences the sheet restates, with the document each comes from. Kept here, next to the
/// sheet, so that changing the wording of a policy shows up as a failing test (see how_it_works_test).
const howItWorksSources = <(LegalDoc, String)>[
  (
    LegalDoc.terms,
    'Your pickup partner counts them at pickup, and the bill follows that count.',
  ),
  (
    LegalDoc.terms,
    'We collect your clothes, iron, wash or dry-clean them as you chose, and deliver them back.',
  ),
  (
    LegalDoc.terms,
    'depending on the service and our workload. The delivery window you pick is our target, not a guarantee.',
  ),
  (LegalDoc.terms, 'We take reasonable care of your garments.'),
  (
    LegalDoc.terms,
    'Tell us about stains, delicate fabrics and expensive embellishments when you hand over your clothes.',
  ),
  (
    LegalDoc.terms,
    'Report any damage or missing item within 48 hours of delivery. We will inspect it and offer a repair, a replacement or a refund.',
  ),
  (LegalDoc.cancellation, 'Before pickup: cancel free in the app.'),
  (
    LegalDoc.cancellation,
    "After pickup, before ironing starts: call us and we'll cancel with a full refund.",
  ),
  (
    LegalDoc.cancellation,
    "Once ironing has started: the order can't be cancelled or refunded.",
  ),
];

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: IdSpace.s2),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: context.text.labelSm.copyWith(color: context.colors.textMuted),
      ),
    ),
  );
}

class _Bullets extends StatelessWidget {
  const _Bullets(this.items);
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: IdSpace.s2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: SizedBox(
                    width: IdSpace.s4,
                    child: Text('•', style: t.body),
                  ),
                ),
                Expanded(child: Text(item, style: t.body)),
              ],
            ),
          ),
      ],
    );
  }
}
