import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design_system/binova_tokens.dart';

abstract final class BinovaTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: BinovaColors.carbon,
      brightness: Brightness.light,
    ).copyWith(
      primary: BinovaColors.carbon,
      onPrimary: BinovaColors.surface,
      secondary: BinovaColors.orange,
      onSecondary: BinovaColors.carbon,
      surface: BinovaColors.surface,
      onSurface: BinovaColors.carbon,
      error: BinovaColors.critical,
      onError: BinovaColors.surface,
    );
    final baseText = ThemeData.light().textTheme.apply(fontFamily: 'Geist');

    return ThemeData(
      useMaterial3: true,
      // BInova targets iOS: Cupertino physics, transitions and text behavior
      // on every platform so previews match the device.
      platform: TargetPlatform.iOS,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: BinovaColors.carbon,
        scaffoldBackgroundColor: BinovaColors.background,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(fontFamily: 'Geist', fontSize: 17, color: BinovaColors.carbon),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: BinovaColors.carbon,
        selectionColor: Color(0x33FF9000),
        selectionHandleColor: BinovaColors.orange,
      ),
      colorScheme: scheme,
      fontFamily: 'Geist',
      scaffoldBackgroundColor: BinovaColors.background,
      textTheme: baseText.copyWith(
        displayLarge: baseText.displayLarge?.copyWith(
          fontSize: 42,
          fontWeight: FontWeight.w600,
          color: BinovaColors.carbon,
          letterSpacing: -1.2,
        ),
        headlineMedium: baseText.headlineMedium?.copyWith(
          fontSize: 34,
          fontWeight: FontWeight.w600,
          color: BinovaColors.carbon,
          letterSpacing: -0.8,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: BinovaColors.carbon,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(
          fontSize: 16,
          color: BinovaColors.carbon,
        ),
        bodyMedium: baseText.bodyMedium?.copyWith(
          fontSize: 14,
          color: BinovaColors.muted,
        ),
      ),
      // Inputs are drawn by each screen (prototype fields have no Material
      // chrome): no fill, no border, no extra padding.
      inputDecorationTheme: const InputDecorationTheme(
        filled: false,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        hintStyle: TextStyle(fontFamily: 'Geist', color: Color(0xFF77756F)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Geist',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: BinovaColors.carbon,
        ),
        iconTheme: IconThemeData(color: BinovaColors.carbon),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: BinovaColors.background,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: BinovaColors.background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: BinovaColors.hairline,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: BinovaColors.graphite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BinovaRadii.input),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: BinovaColors.carbon,
          foregroundColor: BinovaColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BinovaRadii.input),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: BinovaColors.carbon,
          side: const BorderSide(color: BinovaColors.carbon),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BinovaRadii.input),
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
