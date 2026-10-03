import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/phone.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/id_text_field.dart';
import 'auth_repository.dart';
import 'login_controller.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  late final _controller = TextEditingController(text: IndianPhone.format(ref.read(loginProvider).phone));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = IndianPhone.national(_controller.text);
    final opened = await ref.read(loginProvider.notifier).sendCode(phone);
    if (!mounted) return;
    if (opened) {
      unawaited(context.push(Routes.loginCode));
    } else if (ref.read(loginProvider).error == AuthFailureKind.network) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You're offline. Check your connection and try again.")),
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
      AuthFailureKind.unknown => "We couldn't send a code. Try again in a minute.",
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
                  padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s6, IdSpace.s4, IdSpace.s6),
                  children: [
                    Semantics(header: true, child: Text('Enter your mobile number', style: t.headline)),
                    const SizedBox(height: IdSpace.s2),
                    Text("We'll send a 6-digit code to verify it.", style: t.bodyLg.copyWith(color: c.textMuted)),
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
                      autofillHints: const [AutofillHints.telephoneNumberNational],
                      inputFormatters: [IndianPhoneFormatter()],
                      onChanged: (_) => ref.read(loginProvider.notifier).clearError(),
                      onSubmitted: (_) => _submit(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s3, IdSpace.s4, IdSpace.s4),
                child: Column(
                  children: [
                    IdButton(label: 'Get OTP', expand: true, loading: state.busy, onPressed: _submit),
                    const SizedBox(height: IdSpace.s3),
                    Text(
                      'By continuing you agree to our Terms and Privacy Policy.',
                      style: t.caption.copyWith(color: c.textMuted),
                      textAlign: TextAlign.center,
                    ),
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
