import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/surfaces.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.only(top: IdSpace.s3), child: BrandLogo(height: 36)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: IdSpace.s6, vertical: IdSpace.s4),
                child: Column(
                  children: [
                    const SizedBox(height: IdSpace.s4),
                    const _Illustration(),
                    const SizedBox(height: 28),
                    Semantics(
                      header: true,
                      child: Text('Fresh clothes, back at your door.', style: t.headline, textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: IdSpace.s2),
                    Text(
                      'We pick up, iron and deliver. You choose the time.',
                      style: t.bodyLg.copyWith(color: c.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    const _Point(LucideIcons.truck, 'Pickup and delivery from your door'),
                    const _Point(LucideIcons.clock, 'Ironed and back in about a day'),
                    const _Point(LucideIcons.banknote, 'Pay online or in cash at delivery'),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s2, IdSpace.s4, IdSpace.s4),
              child: Column(
                children: [
                  IdButton(label: 'Get started', expand: true, onPressed: () => context.push(Routes.login)),
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
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 208,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(decoration: BoxDecoration(color: context.colors.surfaceSoft, shape: BoxShape.circle)),
            Center(child: Image.asset('assets/brand/irondost-mark.png', width: 168)),
            const Positioned(right: -6, top: 10, child: Bubble(36)),
            const Positioned(right: 34, top: -6, child: Bubble(16)),
            const Positioned(left: 2, bottom: 26, child: Bubble(22)),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: IdSpace.s3),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.surfaceSoft, borderRadius: BorderRadius.circular(IdRadius.sm)),
            child: Icon(icon, size: IdSize.iconMd, color: c.primary),
          ),
          const SizedBox(width: IdSpace.s3),
          Expanded(child: Text(text, style: context.text.body)),
        ],
      ),
    );
  }
}
