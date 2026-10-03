import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../core/phone.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/surfaces.dart';
import '../addresses/addresses_controller.dart';
import '../auth/session.dart';
import '../startup/startup.dart';
import '../support/support.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final profile = switch (ref.watch(sessionProvider).value) {
      SignedIn(:final profile) => profile,
      _ => null,
    };
    final support = Support.of(ref);
    final version = ref.watch(startupProvider).value?.installedVersion;

    return Scaffold(
      appBar: AppBar(title: Text('Account', style: t.headline)),
      body: ListView(
        padding: const EdgeInsets.all(IdSpace.s4),
        children: [
          if (profile != null)
            IdCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: c.primarySoft,
                    child: Text(profile.initials, style: t.title.copyWith(color: c.onPrimarySoft)),
                  ),
                  const SizedBox(width: IdSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.name ?? '', style: t.title),
                        Text(IndianPhone.display(profile.phone), style: t.body.copyWith(color: c.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: IdSpace.s4),
          IdListGroup(
            children: [
              IdListRow(
                icon: LucideIcons.mapPin,
                label: 'Saved addresses',
                value: ref.watch(addressesProvider).value?.length.toString(),
                onTap: () => context.push(Routes.addresses),
              ),
            ],
          ),
          const SizedBox(height: IdSpace.s4),
          IdListGroup(
            children: [
              IdListRow(
                icon: LucideIcons.phone,
                label: 'Call us',
                value: IndianPhone.display(support.phone),
                onTap: () => Support.dial(support.phone),
              ),
              if (support.email != null)
                IdListRow(icon: LucideIcons.mail, label: 'Email us', onTap: () => Support.mail(support.email!)),
            ],
          ),
          const SizedBox(height: IdSpace.s4),
          IdListGroup(
            children: [
              IdListRow(icon: LucideIcons.logOut, label: 'Log out', onTap: () => _confirmLogOut(context, ref)),
            ],
          ),
          const SizedBox(height: IdSpace.s4),
          if (version != null) Text('IronDost $version', style: t.caption.copyWith(color: c.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Future<void> _confirmLogOut(BuildContext context, WidgetRef ref) async {
    final t = context.text;
    final c = context.colors;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(IdSpace.s4, 0, IdSpace.s4, IdSpace.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Log out of IronDost?', style: t.headline),
              const SizedBox(height: IdSpace.s2),
              Text(
                "You'll need a code by SMS to sign in again, and this phone stops getting order updates.",
                style: t.bodyLg.copyWith(color: c.textMuted),
              ),
              const SizedBox(height: IdSpace.s5),
              IdButton(label: 'Log out', expand: true, onPressed: () => Navigator.pop(sheet, true)),
              const SizedBox(height: IdSpace.s2),
              IdButton.outline(label: 'Stay signed in', expand: true, onPressed: () => Navigator.pop(sheet, false)),
            ],
          ),
        ),
      ),
    );
    if (confirmed ?? false) await ref.read(sessionProvider.notifier).signOut();
  }
}
