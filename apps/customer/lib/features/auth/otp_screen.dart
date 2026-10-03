import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/env.dart';
import '../../core/phone.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/otp_input.dart';
import '../../design/widgets/state_view.dart';
import 'auth_repository.dart';
import 'login_controller.dart';
import 'session.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Repaints the resend countdown.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    await ref.read(loginProvider.notifier).verify(code);
    if (!mounted) return;
    if (ref.read(loginProvider).error != null) _code.clear();
  }

  void _changeNumber() {
    ref.read(loginProvider.notifier).reset();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginProvider);
    final c = context.colors;
    final t = context.text;

    ref.listen(sessionProvider, (_, next) {
      if (next.value is WrongApp) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This number belongs to an IronDost staff account. Sign in with another number.')),
        );
        _changeNumber();
      }
    });

    if (state.locked) {
      return Scaffold(
        backgroundColor: c.surface,
        appBar: AppBar(),
        body: StateView(
          icon: LucideIcons.lock,
          tone: StateTone.warning,
          title: 'Too many tries',
          body: "To keep your account safe, we've paused codes for ${IndianPhone.format(state.phone, withCode: true)}. "
              'You can ask for a new one in a little while.',
          primary: IdButton.outline(label: 'Use a different number', onPressed: _changeNumber),
        ),
      );
    }

    final remaining = state.resendAt?.difference(DateTime.now());
    final canResend = remaining == null || remaining.isNegative;
    final error = switch (state.error) {
      AuthFailureKind.invalidCode => 'That code is incorrect. Check the SMS and try again.',
      AuthFailureKind.codeExpired => 'This code has expired. Tap Resend code for a new one.',
      AuthFailureKind.network => "You're offline. Check your connection and try again.",
      AuthFailureKind.unknown => "We couldn't check the code. Try again.",
      _ => null,
    };

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s6, IdSpace.s4, IdSpace.s6),
                children: [
                  Semantics(header: true, child: Text('Enter the code', style: t.headline)),
                  const SizedBox(height: IdSpace.s2),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Sent by SMS to ${IndianPhone.format(state.phone, withCode: true)}.',
                        style: t.bodyLg.copyWith(color: c.textMuted),
                      ),
                      TextButton(onPressed: _changeNumber, child: const Text('Change')),
                    ],
                  ),
                  const SizedBox(height: IdSpace.s5),
                  Text('6-digit code', style: t.labelSm),
                  const SizedBox(height: IdSpace.s3),
                  OtpInput(controller: _code, hasError: error != null, enabled: !state.busy, onCompleted: _verify),
                  const SizedBox(height: IdSpace.s3),
                  if (error != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.circleAlert, size: IdSize.iconSm, color: c.danger),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Semantics(liveRegion: true, child: Text(error, style: t.caption.copyWith(color: c.danger))),
                        ),
                      ],
                    ),
                  const SizedBox(height: IdSpace.s2),
                  if (canResend)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IdButton.text(label: 'Resend code', loading: state.busy, onPressed: ref.read(loginProvider.notifier).resend),
                    )
                  else
                    Text('Resend code in 0:${remaining.inSeconds.toString().padLeft(2, '0')}', style: t.body.copyWith(color: c.textMuted)),
                  const SizedBox(height: IdSpace.s5),
                  _Hint(
                    AppEnv.devAuth
                        ? 'Dev sign-in: any 6 digits work. 000000 acts like a wrong code.'
                        : 'We fill the code in for you when the SMS arrives.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s3, IdSpace.s4, IdSpace.s4),
              child: IdButton(
                label: 'Verify',
                expand: true,
                loading: state.busy,
                onPressed: () {
                  if (_code.text.length == 6) _verify(_code.text);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: IdSpace.s3),
      decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(IdRadius.md)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.messageCircle, size: IdSize.iconMd, color: c.onPrimarySoft),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: context.text.body)),
        ],
      ),
    );
  }
}
