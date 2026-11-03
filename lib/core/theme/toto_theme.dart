import 'package:flutter/material.dart';

import 'brand.dart';
import 'brand_text_styles.dart';
import 'toto_colors.dart';

/// Tema Material 3 de TOTO'S: **solo oscuro**, plano y sin sombras.
///
/// Registra [TotoColors] como `ThemeExtension`, de modo que los widgets leen
/// roles semánticos y nunca hex de marca directamente.
ThemeData totoTheme() {
  const colors = TotoColors.dark;
  const text = BrandTextStyles(colors);

  const scheme = ColorScheme.dark(
    primary: Brand.ovenOrange,
    onPrimary: Brand.boneWhite,
    secondary: Brand.ovenOrange,
    onSecondary: Brand.boneWhite,
    surface: Brand.maroonLift,
    onSurface: Brand.boneWhite,
    error: Brand.ovenOrange,
    onError: Brand.boneWhite,
  );

  final textTheme = TextTheme(
    displayLarge: text.display,
    headlineLarge: text.headingLg,
    headlineMedium: text.heading,
    headlineSmall: text.headingSm,
    titleLarge: text.subheading,
    titleMedium: text.body,
    bodyLarge: text.body,
    bodyMedium: text.bodySm,
    labelLarge: text.label,
    labelMedium: text.navLabel,
    labelSmall: text.caption,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: colors.canvas,
    canvasColor: colors.canvas,
    colorScheme: scheme,
    textTheme: textTheme,
    iconTheme: const IconThemeData(color: Brand.boneWhite),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Brand.signBlack,
      foregroundColor: Brand.boneWhite,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Brand.signBlack,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      height: 64,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: Brand.fontUi,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          color: Brand.boneWhite,
        ),
      ),
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: Brand.boneWhite, size: 22),
      ),
    ),
    cardTheme: const CardThemeData(
      color: Brand.maroonLift,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: Brand.cardRadius,
        side: BorderSide(color: Brand.signBlack),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Brand.maroonLift,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: Brand.cardRadius,
        side: BorderSide(color: Brand.signBlack),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Brand.signBlack,
      modalBackgroundColor: Brand.signBlack,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Brand.ovenOrange,
        foregroundColor: Brand.boneWhite,
        disabledBackgroundColor: Brand.boneWhite30,
        disabledForegroundColor: Brand.boneWhite70,
        minimumSize: const Size(0, Brand.minTouch),
        elevation: 0,
        overlayColor: Colors.transparent,
        textStyle: text.label,
        shape: const RoundedRectangleBorder(borderRadius: Brand.buttonRadius),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Brand.boneWhite,
        minimumSize: const Size(0, Brand.minTouch),
        side: const BorderSide(color: Brand.boneWhite70),
        overlayColor: Colors.transparent,
        textStyle: text.label,
        shape: const RoundedRectangleBorder(borderRadius: Brand.buttonRadius),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Brand.boneWhite,
        overlayColor: Colors.transparent,
        textStyle: text.label,
      ),
    ),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        overlayColor: WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Brand.maroonLift,
      hintStyle: Brand.ui(15, color: Brand.boneWhite70),
      labelStyle: Brand.ui(15, color: Brand.boneWhite70),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Brand.s16,
        vertical: Brand.s12,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: Brand.buttonRadius,
        borderSide: const BorderSide(color: Brand.signBlack),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: Brand.buttonRadius,
        borderSide: const BorderSide(color: Brand.boneWhite),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: Brand.buttonRadius,
        borderSide: const BorderSide(color: Brand.ovenOrange, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: Brand.buttonRadius,
        borderSide: const BorderSide(color: Brand.ovenOrange, width: 2),
      ),
      errorStyle: Brand.ui(12, color: Brand.boneWhite),
    ),
    dividerTheme: const DividerThemeData(
      color: Brand.signBlack,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: Brand.maroonLift,
      iconColor: Brand.boneWhite,
      textColor: Brand.boneWhite,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Brand.signBlack,
      contentTextStyle: Brand.ui(14, color: Brand.boneWhite),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: Brand.buttonRadius),
      elevation: 0,
    ),
  );
}
