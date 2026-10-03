import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../core/phone.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/id_sheet.dart';
import '../../design/widgets/surfaces.dart';
import '../addresses/addresses_controller.dart';
import '../auth/session.dart';
import '../notifications/notifications.dart';
import '../startup/startup.dart';
import 'delete_account.dart';
import 'legal_content.dart';

/// The Account tab: who is signed in, saved addresses, notifications, help, policies, log out and delete account.
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
    final version = ref.watch(startupProvider).value?.installedVersion;
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(title: Semantics(header: true, child: Text('Account', style: t.headline))),
      body: ListView(
        padding: const EdgeInsets.all(IdSpace.s4),
        children: [
          if (profile != null)
            IdCard(
              padding: const EdgeInsets.symmetric(horizontal: IdSpace.s4, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
                    child: ExcludeSemantics(child: Text(profile.initials, textScaler: TextScaler.noScaling, style: t.title.copyWith(color: c.onPrimarySoft))),
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
                  IconButton(
                    tooltip: 'Edit profile',
                    icon: const Icon(LucideIcons.pencil),
                    onPressed: () => context.push(Routes.editProfile),
                  ),
                ],
              ),
            ),
          const SizedBox(height: IdSpace.s4),
          IdListGroup(
            children: [
              IdListRow(icon: LucideIcons.mapPin, label: 'Saved addresses', value: ref.watch(addressesProvider).value?.length.toString(), onTap: () => context.push(Routes.addresses)),
              IdListRow(icon: LucideIcons.bell, label: 'Notifications', value: unread > 0 ? '$unread new' : null, onTap: () => context.push(Routes.notifications)),
              IdListRow(icon: LucideIcons.circleQuestionMark, label: 'Help & support', value: 'Call or email', onTap: () => context.push(Routes.help)),
            ],
          ),
          const SizedBox(height: IdSpace.s4),
          IdListGroup(
            children: [
              for (final doc in LegalDoc.values) IdListRow(icon: doc.icon, label: doc.menuLabel, onTap: () => context.push(Routes.legal(doc.slug))),
            ],
          ),
          const SizedBox(height: IdSpace.s4),
          IdListGroup(
            children: [
              IdListRow(icon: LucideIcons.logOut, label: 'Log out', onTap: () => _confirmLogOut(context, ref)),
              IdListRow(icon: LucideIcons.trash2, label: 'Delete account', destructive: true, onTap: () => confirmDeleteAccount(context, ref)),
            ],
          ),
          const SizedBox(height: IdSpace.s4),
          if (version != null) Text('IronDost $version', style: t.caption.copyWith(color: c.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Future<void> _confirmLogOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showIdSheet<bool>(
      context,
      builder: (sheet) {
        final t = sheet.text;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text('Log out of IronDost?', style: t.headline)),
            const SizedBox(height: IdSpace.s2),
            Text(
              "You'll need a code by SMS to sign in again, and this phone stops getting order updates.",
              style: t.bodyLg.copyWith(color: sheet.colors.textMuted),
            ),
            const SizedBox(height: IdSpace.s5),
            IdButton(label: 'Log out', expand: true, onPressed: () => Navigator.pop(sheet, true)),
            const SizedBox(height: IdSpace.s2),
            IdButton.outline(label: 'Stay signed in', expand: true, onPressed: () => Navigator.pop(sheet, false)),
          ],
        );
      },
    );
    if (confirmed ?? false) await ref.read(sessionProvider.notifier).signOut();
  }
}
