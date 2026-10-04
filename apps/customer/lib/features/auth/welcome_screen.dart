import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/policy_links.dart';
import '../../design/widgets/surfaces.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.surface,
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(IdSpace.s5),
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: BrandLogo(height: 32),
                ),
                const SizedBox(height: IdSpace.s12),
                Semantics(
                  header: true,
                  child: Text(
                    'Fresh clothes, back at your door.',
                    style: context.text.display,
                  ),
                ),
                const SizedBox(height: IdSpace.s4),
                Text(
                  'Ironing, washing and dry cleaning, picked up and delivered.',
                  style: context.text.bodyLg.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
                const SizedBox(height: IdSpace.s6),
                const Divider(),
                const SizedBox(height: IdSpace.s4),
                Text(
                  'Choose your pickup and delivery times.',
                  style: context.text.body,
                ),
                const SizedBox(height: IdSpace.s3),
                Text(
                  'Pay online or in cash at delivery.',
                  style: context.text.body,
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
                  label: 'Get started',
                  expand: true,
                  onPressed: () => context.push(Routes.login),
                ),
                const SizedBox(height: IdSpace.s3),
                const PolicyLinks(),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
