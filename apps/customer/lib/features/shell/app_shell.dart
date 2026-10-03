import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/theme.dart';

/// Bottom navigation: Home, Orders, Offers, Account. Each tab keeps its own back stack;
/// tapping the current tab returns it to its first screen.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: const [
            NavigationDestination(icon: Icon(LucideIcons.house), label: 'Home'),
            NavigationDestination(icon: Icon(LucideIcons.package), label: 'Orders'),
            NavigationDestination(icon: Icon(LucideIcons.badgePercent), label: 'Offers'),
            NavigationDestination(icon: Icon(LucideIcons.user), label: 'Account'),
          ],
        ),
      ),
    );
  }
}
