import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../theme.dart';

/// Independently actionable, keyboard-focusable legal links for signed-out screens.
class PolicyLinks extends StatelessWidget {
  const PolicyLinks({super.key});
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'By continuing, you agree to our',
        style: context.text.caption.copyWith(color: context.colors.textMuted),
        textAlign: TextAlign.center,
      ),
      Wrap(
        alignment: WrapAlignment.center,
        children: [
          TextButton(
            onPressed: () => context.push(Routes.legal('terms')),
            child: const Text('Terms of service'),
          ),
          TextButton(
            onPressed: () => context.push(Routes.legal('privacy')),
            child: const Text('Privacy policy'),
          ),
        ],
      ),
    ],
  );
}
