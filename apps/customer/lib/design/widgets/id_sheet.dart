import 'package:flutter/material.dart';

import '../theme.dart';

/// A short bottom sheet: padded content that scrolls when it is taller than the screen (large text, small phones).
/// Resolves with whatever the content pops it with.
Future<T?> showIdSheet<T>(BuildContext context, {required WidgetBuilder builder}) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Over the tab bar too, so the whole screen is dimmed and the tabs can't be tapped while it is open.
      useRootNavigator: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(IdSpace.s4, 0, IdSpace.s4, IdSpace.s4),
          child: builder(sheet),
        ),
      ),
    );
