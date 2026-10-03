import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/theme.dart';
import 'router.dart';

class IronDostApp extends ConsumerWidget {
  const IronDostApp({super.key, this.font = googleFont});

  /// Tests pass [plainFont] so no fonts are downloaded.
  final FontResolver font;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'IronDost',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light, font: font),
      darkTheme: buildTheme(Brightness.dark, font: font),
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('en', 'IN'),
      supportedLocales: const [Locale('en', 'IN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
