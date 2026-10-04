import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../core/phone.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/id_text_field.dart';
import '../auth/session.dart';

/// Name and email can be changed; the mobile number signs the customer in, so it is shown but locked.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  String? _nameError;
  String? _emailError;
  bool _saving = false;
  bool _prefilled = false;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Profile? get _profile => switch (ref.read(sessionProvider).value) {
    SignedIn(:final profile) => profile,
    _ => null,
  };

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _profile?.name ?? '');
    _email = TextEditingController(text: _profile?.email ?? '');
    _prefilled = _profile != null;
  }

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
      _nameError = name.length < 2
          ? 'Enter your name, as your partner should call you.'
          : null;
      _emailError = email.isNotEmpty && !_emailPattern.hasMatch(email)
          ? 'Enter a valid email, like you@example.com.'
          : null;
    });
    if (_nameError != null || _emailError != null) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(sessionProvider.notifier)
          .saveProfile(name: name, email: email);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (e) {
      if (!mounted) return;
      final failure = ApiFailure.from(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failure.isConnectivity
                ? "You're offline. Check your connection and try again."
                : "We couldn't save that. Try again.",
          ),
        ),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final profile = switch (ref.watch(sessionProvider).value) {
      SignedIn(:final profile) => profile,
      _ => null,
    };
    if (!_prefilled && profile != null) {
      _name.text = profile.name ?? '';
      _email.text = profile.email ?? '';
      _prefilled = true;
    }
    // Initials follow the name as it is typed.
    final initials = Profile(
      id: '',
      phone: '',
      name: _name.text,
      isComplete: true,
    ).initials;

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.account),
        ),
        title: Text('Edit profile', style: t.titleLg),
      ),
      body: SafeArea(
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
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: ExcludeSemantics(
                          child: Text(
                            initials,
                            textScaler: TextScaler.noScaling,
                            style: t.headline.copyWith(color: c.onPrimarySoft),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: IdSpace.s6),
                    IdTextField(
                      label: 'Full name',
                      controller: _name,
                      error: _nameError,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: IdSpace.s6),
                    IdTextField(
                      label: 'Email (optional)',
                      controller: _email,
                      hint: 'you@example.com',
                      help: 'For receipts.',
                      error: _emailError,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      onSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: IdSpace.s6),
                    _LockedPhone(phone: profile?.phone),
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
                child: IdButton(
                  label: 'Save changes',
                  expand: true,
                  loading: _saving,
                  onPressed: profile == null ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The mobile number, read only, with how to change it.
class _LockedPhone extends StatelessWidget {
  const _LockedPhone({required this.phone});
  final String? phone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final shown = phone == null ? '' : IndianPhone.display(phone!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mobile number',
          style: t.label.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Semantics(
          readOnly: true,
          label: 'Mobile number, $shown, cannot be changed',
          excludeSemantics: true,
          child: Container(
            height: IdSize.inputHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: c.surfaceSoft,
              borderRadius: BorderRadius.circular(IdRadius.md),
            ),
            child: Row(
              children: [
                Expanded(child: Text(shown, style: t.bodyLg)),
                Icon(LucideIcons.lock, size: IdSize.iconMd, color: c.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Your number signs you in. Contact support to change it.',
            style: t.caption.copyWith(color: c.textMuted),
          ),
        ),
        IdButton.text(
          label: 'Contact support',
          onPressed: () => context.push(Routes.help),
        ),
      ],
    );
  }
}
