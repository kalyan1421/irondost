import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../core/phone.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/id_sheet.dart';
import '../../design/widgets/screen_backdrop.dart';
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

    return ScreenBackdrop(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: false,
        toolbarHeight: 72,
        titleSpacing: IdSpace.s5,
        title: Semantics(
          header: true,
          child: Text('Profile', style: t.display.copyWith(fontSize: 32, height: 1.2)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(IdSpace.s5),
        children: [
          if (profile != null)
            IdCard(
              padding: const EdgeInsets.symmetric(
                horizontal: IdSpace.s5,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [c.royal, c.sky],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        profile.initials,
                        textScaler: TextScaler.noScaling,
                        style: t.title.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: IdSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.name ?? '', style: t.title),
                        if (profile.phone != null)
                          Text(
                            IndianPhone.display(profile.phone!),
                            style: t.body.copyWith(color: c.textMuted),
                          )
                        else
                          Text(
                            profile.email ?? 'No mobile number yet',
                            style: t.body.copyWith(color: c.textMuted),
                          ),
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
          if (profile != null && profile.phone == null) ...[
            const SizedBox(height: IdSpace.s4),
            // Signed in with Google: no verified number yet, and bookings need one.
            _AddPhoneBanner(onTap: () => context.push<bool>(Routes.addPhone)),
          ],
          const SizedBox(height: IdSpace.s4),
          IdListGroup(
            children: [
              IdListRow(
                icon: LucideIcons.mapPin,
                label: 'Saved addresses',
                value: ref.watch(addressesProvider).value?.length.toString(),
                onTap: () => context.push(Routes.addresses),
              ),
              IdListRow(
                icon: LucideIcons.bell,
                label: 'Notifications',
                value: unread > 0 ? '$unread new' : null,
                onTap: () => context.push(Routes.notifications),
              ),
              IdListRow(icon: LucideIcons.badgePercent, label: 'Offers and codes', onTap: () => context.push(Routes.offers)),
              IdListRow(icon: LucideIcons.messageSquare, label: 'Your reports', onTap: () => context.push(Routes.issues)),
              IdListRow(
                icon: LucideIcons.circleQuestionMark,
                label: 'Help and support',
                value: 'Call or email',
                onTap: () => context.push(Routes.help),
              ),
            ],
          ),
          const SizedBox(height: IdSpace.s4),
          IdListGroup(
            children: [
              for (final doc in LegalDoc.values)
                IdListRow(
                  icon: doc.icon,
                  label: doc.menuLabel,
                  onTap: () => context.push(Routes.legal(doc.slug)),
                ),
            ],
          ),
          const SizedBox(height: IdSpace.s4),
          IdListGroup(
            children: [
              IdListRow(
                icon: LucideIcons.logOut,
                label: 'Log out',
                onTap: () => _confirmLogOut(context, ref),
              ),
              IdListRow(
                icon: LucideIcons.trash2,
                label: 'Delete account',
                destructive: true,
                onTap: () => confirmDeleteAccount(context, ref),
              ),
            ],
          ),
          const SizedBox(height: IdSpace.s4),
          if (version != null)
            Text(
              'IronDost $version',
              style: t.caption.copyWith(color: c.textMuted),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    ));
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
            Semantics(
              header: true,
              child: Text('Log out of IronDost?', style: t.headline),
            ),
            const SizedBox(height: IdSpace.s2),
            Text(
              "You'll need to sign in again to see your orders, and this phone stops getting order updates.",
              style: t.bodyLg.copyWith(color: sheet.colors.textMuted),
            ),
            const SizedBox(height: IdSpace.s5),
            IdButton(
              label: 'Log out',
              expand: true,
              onPressed: () => Navigator.pop(sheet, true),
            ),
            const SizedBox(height: IdSpace.s2),
            IdButton.outline(
              label: 'Stay signed in',
              expand: true,
              onPressed: () => Navigator.pop(sheet, false),
            ),
          ],
        );
      },
    );
    if (confirmed ?? false) await ref.read(sessionProvider.notifier).signOut();
  }
}

/// The yellow prompt for a customer with no mobile number: the pickup partner needs one to call.
class _AddPhoneBanner extends StatelessWidget {
  const _AddPhoneBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      button: true,
      label: 'Add mobile number. So the pickup partner can call you.',
      excludeSemantics: true,
      child: Material(
        color: c.offerSoft,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(IdSpace.s4),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(LucideIcons.phone, size: IdSize.iconMd, color: c.text),
                ),
                const SizedBox(width: IdSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add mobile number', style: t.title),
                      Text(
                        'So the pickup partner can call you.',
                        style: t.caption.copyWith(color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                Text('Add', style: t.label.copyWith(color: c.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
