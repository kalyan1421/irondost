import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../core/phone.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../auth/session.dart';
import 'area_interest.dart';

/// "Tell me when you're here" for a saved address outside the service area: the consent in plain words, one button, and
/// what happened. A customer with no mobile number is asked to add one first, because that number is how we reach them.
class TellMeWhenHere extends ConsumerWidget {
  const TellMeWhenHere({super.key, required this.addressId, required this.place});

  final String addressId;

  /// "Gachibowli": the area or city, as in "We're not in Gachibowli yet".
  final String place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final state = ref.watch(tellMeProvider(addressId));
    final session = ref.watch(sessionProvider).value;
    final profile = session is SignedIn ? session.profile : null;
    final hasPhone = profile?.hasPhone ?? true;

    if (state.done) {
      return Semantics(
        liveRegion: true,
        container: true,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: c.successSoft, borderRadius: BorderRadius.circular(IdRadius.md)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.circleCheck, size: IdSize.iconMd, color: c.success),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Thanks. We'll get in touch when we start picking up from $place.",
                  style: t.body,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final problem = state.problem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hasPhone)
          IdButton.outline(
            label: 'Add your mobile number',
            icon: LucideIcons.phone,
            expand: true,
            onPressed: () => context.push<bool>(Routes.addPhone),
          )
        else
          IdButton.outline(
            label: "Tell me when you're here",
            icon: LucideIcons.bellRing,
            expand: true,
            loading: state.sending,
            onPressed: () => ref.read(tellMeProvider(addressId).notifier).send(),
          ),
        const SizedBox(height: IdSpace.s2),
        Text(
          hasPhone
              ? tellMeConsent(place: place, phone: profile?.phone == null ? null : IndianPhone.display(profile!.phone!))
              : 'We need a mobile number to reach you when we start picking up from $place.',
          style: t.caption.copyWith(color: c.textMuted),
        ),
        if (problem != null) ...[
          const SizedBox(height: IdSpace.s2),
          Semantics(
            liveRegion: true,
            child: Text(tellMeProblemText(problem), style: t.body.copyWith(color: problem == TellMeProblem.nowServed ? c.success : c.danger)),
          ),
        ],
      ],
    );
  }
}
