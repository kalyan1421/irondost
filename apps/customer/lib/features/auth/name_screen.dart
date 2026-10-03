import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/id_text_field.dart';
import 'session.dart';

/// Shown once after the first sign-in, until the customer has a name.
class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key});

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  String? _nameError;
  String? _emailError;
  bool _saving = false;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    setState(() {
      _nameError = name.length < 2 ? 'Enter your name, as your partner should call you.' : null;
      _emailError = email.isNotEmpty && !_emailPattern.hasMatch(email) ? 'Enter a valid email, like you@example.com.' : null;
    });
    if (_nameError != null || _emailError != null) return;

    setState(() => _saving = true);
    try {
      await ref.read(sessionProvider.notifier).saveProfile(name: name, email: email);
    } catch (e) {
      if (!mounted) return;
      final failure = ApiFailure.from(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failure.isConnectivity ? "You're offline. Check your connection and try again." : "We couldn't save that. Try again.",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: AutofillGroup(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s3, IdSpace.s4, 0),
                child: Row(
                  children: [
                    Text('Step 1 of 2', style: t.caption.copyWith(color: c.textMuted)),
                    const SizedBox(width: IdSpace.s3),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(value: 0.5, minHeight: 4, color: c.primary, backgroundColor: c.surfaceSoft),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s6, IdSpace.s4, IdSpace.s6),
                  children: [
                    Semantics(header: true, child: Text('What should we call you?', style: t.headline)),
                    const SizedBox(height: IdSpace.s2),
                    Text('Your partner uses your name at pickup.', style: t.bodyLg.copyWith(color: c.textMuted)),
                    const SizedBox(height: 28),
                    IdTextField(
                      label: 'Full name',
                      controller: _name,
                      error: _nameError,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                    ),
                    const SizedBox(height: IdSpace.s5),
                    IdTextField(
                      label: 'Email (optional)',
                      controller: _email,
                      hint: 'you@example.com',
                      help: 'For receipts. We never send marketing without asking.',
                      error: _emailError,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      onSubmitted: (_) => _save(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s3, IdSpace.s4, IdSpace.s4),
                child: IdButton(label: 'Continue', expand: true, loading: _saving, onPressed: _save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
