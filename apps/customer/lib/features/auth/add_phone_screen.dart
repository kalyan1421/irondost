import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/phone.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/id_text_field.dart';
import 'session.dart';

/// Where a customer types the mobile number the pickup partner calls: from checkout the first time they book (a Google
/// customer has none), or from their account to correct it. There is no SMS code. Pops `true` once the number is saved.
class AddPhoneScreen extends ConsumerStatefulWidget {
  const AddPhoneScreen({super.key});

  @override
  ConsumerState<AddPhoneScreen> createState() => _AddPhoneScreenState();
}

class _AddPhoneScreenState extends ConsumerState<AddPhoneScreen> {
  late final _controller = TextEditingController(text: IndianPhone.format(IndianPhone.national(_current ?? '')));
  String? _error;
  bool _saving = false;

  String? get _current => switch (ref.read(sessionProvider).value) {
    SignedIn(:final profile) => profile.phone,
    _ => null,
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final phone = IndianPhone.national(_controller.text);
    if (!IndianPhone.isValid(phone)) {
      setState(() => _error = 'Enter a 10-digit mobile number.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).savePhone(phone);
      if (mounted) context.pop(true);
    } catch (e) {
      if (!mounted) return;
      final failure = ApiFailure.from(e);
      setState(() {
        _saving = false;
        _error = switch (failure.code) {
          'INVALID_PHONE' => 'Enter a 10-digit mobile number.',
          _ when failure.isConnectivity => "You're offline. Check your connection and try again.",
          _ => "We couldn't save your number. Try again.",
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final changing = _current != null;

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
                  padding: const EdgeInsets.fromLTRB(IdSpace.s5, IdSpace.s6, IdSpace.s5, IdSpace.s6),
                  children: [
                    Semantics(
                      header: true,
                      child: Text(changing ? 'Change your mobile number' : 'Add your mobile number', style: t.headline),
                    ),
                    const SizedBox(height: IdSpace.s2),
                    Text(
                      'Your pickup partner calls this number if needed.',
                      style: t.bodyLg.copyWith(color: c.textMuted),
                    ),
                    const SizedBox(height: IdSpace.s8),
                    IdTextField(
                      label: 'Mobile number',
                      controller: _controller,
                      prefixText: '+91',
                      hint: '98765 43210',
                      error: _error,
                      autofocus: true,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.telephoneNumberNational],
                      inputFormatters: [IndianPhoneFormatter()],
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      onSubmitted: (_) => _save(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(IdSpace.s5, IdSpace.s3, IdSpace.s5, IdSpace.s4),
                child: IdButton(label: 'Save number', expand: true, loading: _saving, onPressed: _save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
