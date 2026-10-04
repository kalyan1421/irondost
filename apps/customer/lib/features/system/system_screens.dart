import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/phone.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/state_view.dart';
import '../../design/widgets/surfaces.dart';
import '../auth/session.dart';
import '../startup/startup.dart';
import '../support/support.dart';

/// Shown while the app checks the API and the saved sign-in.
class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.surface,
    body: const Center(child: BrandLogo(height: 32)),
  );
}

/// No internet, or the API is down. Retries whatever failed.
class UnavailableScreen extends ConsumerWidget {
  const UnavailableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(startupProvider);
    final session = ref.watch(sessionProvider);
    final error = startup.error ?? session.error;
    final failure = error == null ? null : ApiFailure.from(error);
    final retrying = startup.isLoading || session.isLoading;

    void retry() {
      if (startup.hasError) {
        ref.invalidate(startupProvider);
      } else {
        ref.read(sessionProvider.notifier).retry();
      }
    }

    final offline = failure?.isConnectivity ?? false;
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: offline
          ? StateView(
              icon: LucideIcons.wifiOff,
              title: "You're offline",
              body: 'Check your Wi-Fi or mobile data, then try again.',
              primary: IdButton(
                label: 'Try again',
                icon: LucideIcons.refreshCw,
                loading: retrying,
                expand: true,
                onPressed: retry,
              ),
            )
          : StateView(
              icon: LucideIcons.cloudOff,
              tone: StateTone.primary,
              title: "We'll be right back",
              body: "IronDost isn't responding right now. We can't check your order status. Please try again in a few minutes.",
              primary: IdButton(
                label: 'Try again',
                icon: LucideIcons.refreshCw,
                loading: retrying,
                expand: true,
                onPressed: retry,
              ),
              secondary: IdButton.outline(
                label: 'Call ${IndianPhone.display(Support.fallbackPhone)}',
                icon: LucideIcons.phone,
                expand: true,
                onPressed: () => Support.dial(Support.fallbackPhone),
              ),
            ),
    );
  }
}

/// This build is below the minimum version.
class UpdateScreen extends ConsumerWidget {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(startupProvider).value;
    final version = startup?.version;
    final storeUrl = version?.storeUrl;
    Future<void> openStore() async {
      var opened = false;
      try {
        final uri = storeUrl == null ? null : Uri.tryParse(storeUrl);
        if (uri != null) {
          opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        // A missing store application should leave a useful recovery path.
      }
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Couldn’t open the update link. Contact support for help updating.',
            ),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: StateView(
        icon: LucideIcons.download,
        tone: StateTone.primary,
        title: 'Update to continue',
        body: version?.message ?? 'This version of IronDost is no longer supported. Install the latest version to continue.',
        caption: storeUrl == null
            ? 'The update link is unavailable. Contact support for help.'
            : 'You have ${startup!.installedVersion} · Latest is ${version!.latestVersion}',
        primary: IdButton(
          label: 'Update now',
          expand: true,
          onPressed: storeUrl == null ? null : openStore,
        ),
        secondary: IdButton.outline(
          label: 'Contact support',
          expand: true,
          onPressed: () => Support.dial(Support.of(ref).phone),
        ),
      ),
    );
  }
}

/// Staff disabled the account, or a staff number opened the customer app.
class PausedScreen extends ConsumerWidget {
  const PausedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final support = Support.of(ref);
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: StateView(
        icon: LucideIcons.circlePause,
        tone: StateTone.warning,
        title: 'Your account is paused',
        body: "You can't book pickups right now. Call or email us and we'll sort it out.",
        primary: IdButton(
          label: 'Call ${IndianPhone.display(support.phone)}',
          icon: LucideIcons.phone,
          expand: true,
          onPressed: () => Support.dial(support.phone),
        ),
        secondary: support.email == null
            ? null
            : IdButton.outline(
                label: 'Email support',
                icon: LucideIcons.mail,
                expand: true,
                onPressed: () => Support.mail(support.email!),
              ),
        tertiary: IdButton.text(
          label: 'Log out',
          expand: true,
          onPressed: () => ref.read(sessionProvider.notifier).signOut(),
        ),
      ),
    );
  }
}
