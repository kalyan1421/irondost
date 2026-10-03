import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.g.dart';

export 'tokens.g.dart';

/// Builds a TextStyle for a font family. The app uses Google Fonts; tests pass a resolver
/// that uses plain family names so nothing is fetched.
typedef FontResolver = TextStyle Function(String family, TextStyle style);

TextStyle googleFont(String family, TextStyle style) => GoogleFonts.getFont(family, textStyle: style);
TextStyle plainFont(String family, TextStyle style) => style.copyWith(fontFamily: family);

/// The design system's named text styles, coloured for the current theme. Read with `context.text`.
@immutable
class IdTextStyles extends ThemeExtension<IdTextStyles> {
  const IdTextStyles({
    required this.display,
    required this.headline,
    required this.titleLg,
    required this.title,
    required this.bodyLg,
    required this.body,
    required this.label,
    required this.labelSm,
    required this.caption,
    required this.orderId,
  });

  final TextStyle display;
  final TextStyle headline;
  final TextStyle titleLg;
  final TextStyle title;
  final TextStyle bodyLg;
  final TextStyle body;
  final TextStyle label;
  final TextStyle labelSm;
  final TextStyle caption;
  final TextStyle orderId;

  factory IdTextStyles.of(IdColors c, FontResolver font) {
    TextStyle s(IdTypeSpec spec) => font(
          spec.family,
          TextStyle(
            fontSize: spec.size,
            height: spec.lineHeight / spec.size,
            fontWeight: spec.weight,
            letterSpacing: spec.letterSpacingEm * spec.size,
            color: c.text,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        );
    return IdTextStyles(
      display: s(IdType.display),
      headline: s(IdType.headline),
      titleLg: s(IdType.titleLg),
      title: s(IdType.title),
      bodyLg: s(IdType.bodyLg),
      body: s(IdType.body),
      label: s(IdType.label),
      labelSm: s(IdType.labelSm),
      caption: s(IdType.caption),
      orderId: s(IdType.orderId),
    );
  }

  @override
  IdTextStyles copyWith() => this;

  @override
  IdTextStyles lerp(IdTextStyles? other, double t) {
    if (other == null) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return IdTextStyles(
      display: l(display, other.display),
      headline: l(headline, other.headline),
      titleLg: l(titleLg, other.titleLg),
      title: l(title, other.title),
      bodyLg: l(bodyLg, other.bodyLg),
      body: l(body, other.body),
      label: l(label, other.label),
      labelSm: l(labelSm, other.labelSm),
      caption: l(caption, other.caption),
      orderId: l(orderId, other.orderId),
    );
  }
}

extension IdThemeContext on BuildContext {
  IdColors get colors => Theme.of(this).extension<IdColors>()!;
  IdShadows get shadows => Theme.of(this).extension<IdShadows>()!;
  IdTextStyles get text => Theme.of(this).extension<IdTextStyles>()!;
}

/// Material theme for IronDost, following the platform mapping in the design system's README.
ThemeData buildTheme(Brightness brightness, {FontResolver font = googleFont}) {
  final dark = brightness == Brightness.dark;
  final c = dark ? IdColors.dark : IdColors.light;
  final text = IdTextStyles.of(c, font);

  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.primary,
    onPrimary: c.onPrimary,
    primaryContainer: c.primarySoft,
    onPrimaryContainer: c.onPrimarySoft,
    secondary: c.accent,
    onSecondary: c.surface,
    tertiary: c.offer,
    onTertiary: c.onOffer,
    tertiaryContainer: c.offerSoft,
    onTertiaryContainer: c.text,
    error: c.danger,
    onError: c.surface,
    errorContainer: c.dangerSoft,
    onErrorContainer: c.danger,
    surface: c.surface,
    onSurface: c.text,
    onSurfaceVariant: c.textMuted,
    surfaceContainerLowest: c.surface,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surfaceSoft,
    surfaceContainerHighest: c.surfaceSoft,
    outline: c.borderStrong,
    outlineVariant: c.border,
    inverseSurface: c.surfaceInverse,
    onInverseSurface: c.textInverse,
    inversePrimary: c.inverseAccent,
    shadow: Colors.black,
    scrim: c.scrim,
  );

  final textTheme = TextTheme(
    headlineLarge: text.display,
    headlineMedium: text.headline,
    headlineSmall: text.headline,
    titleLarge: text.titleLg,
    titleMedium: text.title,
    titleSmall: text.label,
    bodyLarge: text.bodyLg,
    bodyMedium: text.body,
    bodySmall: text.caption.copyWith(color: c.textMuted),
    labelLarge: text.label,
    labelMedium: text.labelSm,
    labelSmall: text.caption,
  );

  const buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(IdRadius.md)));
  const buttonSize = Size(IdSize.touchTarget, IdSize.buttonHeight);
  const buttonPadding = EdgeInsets.symmetric(horizontal: IdSpace.s5);
  OutlineInputBorder inputBorder(Color color, double width) => OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(IdRadius.md)),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    textTheme: textTheme,
    extensions: [c, dark ? IdShadows.dark : IdShadows.light, text],
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: c.surface,
      foregroundColor: c.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: IdSize.appBar,
      titleTextStyle: text.titleLg,
      iconTheme: IconThemeData(color: c.text, size: IdSize.iconLg),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        disabledBackgroundColor: c.primary.withValues(alpha: 0.38),
        disabledForegroundColor: c.onPrimary,
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: text.label,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: buttonShape,
        side: BorderSide(color: c.borderStrong),
        textStyle: text.label,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.primary,
        minimumSize: const Size(IdSize.touchTarget, IdSize.touchTarget),
        padding: const EdgeInsets.symmetric(horizontal: IdSpace.s3),
        shape: buttonShape,
        textStyle: text.label,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: c.text,
        minimumSize: const Size(IdSize.touchTarget, IdSize.touchTarget),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: text.bodyLg.copyWith(color: c.textMuted),
      helperStyle: text.caption.copyWith(color: c.textMuted),
      errorStyle: text.caption.copyWith(color: c.danger),
      helperMaxLines: 3,
      errorMaxLines: 3,
      border: inputBorder(c.borderStrong, 1),
      enabledBorder: inputBorder(c.borderStrong, 1),
      focusedBorder: inputBorder(c.primary, 2),
      errorBorder: inputBorder(c.danger, 2),
      focusedErrorBorder: inputBorder(c.danger, 2),
      disabledBorder: inputBorder(c.border, 1),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: IdSize.bottomNav,
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.primarySoft,
      indicatorShape: const StadiumBorder(),
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected) ? c.text : c.textMuted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: IdSize.iconLg,
          color: states.contains(WidgetState.selected) ? c.onPrimarySoft : c.textMuted,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.surfaceInverse,
      contentTextStyle: text.body.copyWith(color: c.textInverse, fontWeight: FontWeight.w500),
      actionTextColor: c.inverseAccent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(IdRadius.md))),
      insetPadding: const EdgeInsets.fromLTRB(IdSpace.s4, 0, IdSpace.s4, IdSpace.s4),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: c.scrim,
      showDragHandle: true,
      dragHandleColor: c.borderStrong,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(IdRadius.xl))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      barrierColor: c.scrim,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(IdRadius.xl))),
      titleTextStyle: text.titleLg,
      contentTextStyle: text.body.copyWith(color: c.textMuted),
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(IdRadius.lg)),
        side: dark ? BorderSide(color: c.border) : BorderSide.none,
      ),
    ),
    dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary, linearTrackColor: c.surfaceSoft),
    listTileTheme: ListTileThemeData(
      iconColor: c.textMuted,
      textColor: c.text,
      titleTextStyle: text.bodyLg.copyWith(fontWeight: FontWeight.w500),
      subtitleTextStyle: text.body.copyWith(color: c.textMuted),
      minVerticalPadding: IdSpace.s3,
      contentPadding: const EdgeInsets.symmetric(horizontal: IdSpace.s4),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.onPrimary : c.textMuted),
      trackColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) return s.contains(WidgetState.disabled) ? c.primary.withValues(alpha: 0.5) : c.primary;
        return c.surfaceSoft;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.transparent : c.borderStrong),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.primary,
      selectionColor: c.primarySoft,
      selectionHandleColor: c.primary,
    ),
  );
}
