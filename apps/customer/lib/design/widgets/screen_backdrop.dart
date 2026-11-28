import 'package:flutter/material.dart';

import '../theme.dart';

/// The soft sky-to-white ground behind the four tab screens. Dark theme keeps the plain app background.
class ScreenBackdrop extends StatelessWidget {
  const ScreenBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.bg,
        gradient: dark
            ? null
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF6F9FF),
                  Color(0xFFEEF4FD),
                  Color(0xFFE6EFFC),
                ],
                stops: [0, 0.4, 1],
              ),
      ),
      child: child,
    );
  }
}
