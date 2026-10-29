import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/phone.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/id_text_field.dart';
import '../../design/widgets/policy_links.dart';
import 'auth_repository.dart';
import 'google_sign_in_button.dart';
import 'login_controller.dart';

/// Sign in with a mobile number, or (with [linking]) add a verified number to a Google customer's account before booking.
/// When linking, the screen pops `true` once the number is stored.
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key, this.linking = false});

  final bool linking;

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  late final _controller = TextEditingController(
    text: IndianPhone.format(ref.read(loginProvider).phone),
  );

  @override
  void initState() {
    super.initState();
    if (widget.linking) unawaited(Future.microtask(_finishIfAlreadyLinked));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The account may already carry a verified number the API has not heard about yet: then there is nothing to type.
  Future<void> _finishIfAlreadyLinked() async {
    if (await ref.read(loginProvider.notifier).syncLinkedPhone() && mounted) context.pop(true);
  }

  Future<void> _submit() async {
    final linking = widget.linking;
    final phone = IndianPhone.national(_controller.text);
    final opened = await ref.read(loginProvider.notifier).sendCode(phone, link: linking);
    if (!mounted) return;
    if (linking && ref.read(loginProvider).linked) {
      // Android read the code itself: the number is stored already.
      context.pop(true);
    } else if (opened) {
      if (linking) {
        final added = await context.push<bool>(Routes.addPhoneCode);
        if (added == true && mounted) context.pop(true);
      } else {
        unawaited(context.push(Routes.loginCode));
      }
    } else if (ref.read(loginProvider).error == AuthFailureKind.network) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You're offline. Check your connection and try again."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginProvider);
    final c = context.colors;
    final t = context.text;
    final error = switch (state.error) {
      AuthFailureKind.invalidNumber => 'Enter a 10-digit mobile number.',
      AuthFailureKind.phoneInUse => 'This number is already linked to another IronDost account. Use a different number.',
      AuthFailureKind.unknown =>
        "We couldn't send a code. Try again in a minute.",
      _ => null,
    };

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: AutofillGroup(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    IdSpace.s5,
                    IdSpace.s6,
                    IdSpace.s5,
                    IdSpace.s6,
                  ),
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        widget.linking ? 'Add your mobile number' : 'Enter your mobile number',
                        style: t.headline,
                      ),
                    ),
                    const SizedBox(height: IdSpace.s2),
                    Text(
                      widget.linking
                          ? "Your pickup partner calls this number if needed. We'll send a 6-digit code to verify it."
                          : "We'll send a 6-digit code to verify it.",
                      style: t.bodyLg.copyWith(color: c.textMuted),
                    ),
                    const SizedBox(height: IdSpace.s8),
                    IdTextField(
                      label: 'Mobile number',
                      controller: _controller,
                      prefixText: '+91',
                      hint: '98765 43210',
                      help: 'Your pickup partner will call this number if needed.',
                      error: error,
                      autofocus: true,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [
                        AutofillHints.telephoneNumberNational,
                      ],
                      inputFormatters: [IndianPhoneFormatter()],
                      onChanged: (_) =>
                          ref.read(loginProvider.notifier).clearError(),
                      onSubmitted: (_) => _submit(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  IdSpace.s5,
                  IdSpace.s3,
                  IdSpace.s5,
                  IdSpace.s4,
                ),
                child: Column(
                  children: [
                    IdButton(
                      label: 'Send code',
                      expand: true,
                      loading: state.busy,
                      onPressed: _submit,
                    ),
                    if (!widget.linking) ...[
                      const SizedBox(height: IdSpace.s3),
                      const OrDivider(),
                      const SizedBox(height: IdSpace.s3),
                      const GoogleSignInButton(),
                    ],
                    const SizedBox(height: IdSpace.s3),
                    const PolicyLinks(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
