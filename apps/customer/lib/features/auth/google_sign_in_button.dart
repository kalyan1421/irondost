import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import 'auth_repository.dart';
import 'login_controller.dart';

/// "Continue with Google": signs in, or signs up on the first time. A Google customer adds a verified mobile number
/// later, when they first book (see the add-number screens).
class GoogleSignInButton extends ConsumerWidget {
  const GoogleSignInButton({super.key});

  Future<void> _signIn(BuildContext context, WidgetRef ref) async {
    final failure = await ref.read(loginProvider.notifier).signInWithGoogle();
    if (!context.mounted || failure == null) return;
    final message = switch (failure) {
      // They closed the account picker themselves.
      AuthFailureKind.googleCancelled => null,
      AuthFailureKind.googleUnavailable => "Google sign-in isn't available in this version yet. Use your mobile number instead.",
      AuthFailureKind.network => "You're offline. Check your connection and try again.",
      _ => "We couldn't sign you in with Google. Try again, or use your mobile number.",
    };
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(loginProvider.select((s) => s.googleBusy));
    final phoneBusy = ref.watch(loginProvider.select((s) => s.busy));
    return IdButton.outline(
      label: 'Continue with Google',
      expand: true,
      loading: busy,
      onPressed: phoneBusy ? null : () => _signIn(context, ref),
    );
  }
}

/// A quiet "or" between the two ways to sign in.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(child: Divider(color: c.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: IdSpace.s3),
          child: Text('or', style: context.text.caption.copyWith(color: c.textMuted)),
        ),
        Expanded(child: Divider(color: c.border)),
      ],
    );
  }
}
