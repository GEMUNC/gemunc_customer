import 'package:eshop_plus/core/constants/themeConstants.dart';
import 'package:eshop_plus/core/theme/colors.dart';
import 'package:eshop_plus/commons/models/store.dart';
import 'package:eshop_plus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData getThemeData(BuildContext context, Store defaultStore) {
    final baseTextTheme = GoogleFonts.rubikTextTheme(Theme.of(context).textTheme);
    final themeSecondaryColor = Utils.getColorFromHexValue(defaultStore.secondaryColor) ?? secondaryColor;
    final themePrimaryColor = Utils.getColorFromHexValue(defaultStore.primaryColor) ?? primaryColor;
    final themeBackgroundColor = Utils.getColorFromHexValue(defaultStore.backgroundColor) ?? const Color(0xFFF5F8F9);
    final whiteColor = Colors.white;
    final borderColorAlpha = borderColor.withValues(alpha: 0.4);
    final secondaryColorAlpha = secondaryColor.withValues(alpha: 0.67);
    final shadowColorConst = const Color(0x3F000000);
    
    return Theme.of(context).copyWith(
        textTheme: baseTextTheme.copyWith(
          // Apply secondary color to all text styles by default
          displayLarge: baseTextTheme.displayLarge?.copyWith(color: themeSecondaryColor),
          displayMedium: baseTextTheme.displayMedium?.copyWith(color: themeSecondaryColor),
          displaySmall: baseTextTheme.displaySmall?.copyWith(color: themeSecondaryColor),
          headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: themeSecondaryColor),
          headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: themeSecondaryColor),
          headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: themeSecondaryColor),
          titleLarge: baseTextTheme.titleLarge?.copyWith(color: themeSecondaryColor),
          titleMedium: baseTextTheme.titleMedium?.copyWith(color: themeSecondaryColor),
          titleSmall: baseTextTheme.titleSmall?.copyWith(color: themeSecondaryColor),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: themeSecondaryColor),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: themeSecondaryColor),
          bodySmall: baseTextTheme.bodySmall?.copyWith(color: themeSecondaryColor),
          labelLarge: baseTextTheme.labelLarge?.copyWith(color: themeSecondaryColor),
          labelMedium: baseTextTheme.labelMedium?.copyWith(color: themeSecondaryColor),
          labelSmall: baseTextTheme.labelSmall?.copyWith(color: themeSecondaryColor),
        ),
        secondaryHeaderColor: themeSecondaryColor,
        scaffoldBackgroundColor: themeBackgroundColor,
        shadowColor: shadowColorConst,
        hintColor: themeSecondaryColor.withValues(alpha: 0.67),
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        iconTheme: IconThemeData(color: themeSecondaryColor),
        dividerColor: borderColorAlpha,
        inputDecorationTheme: InputDecorationTheme(
          iconColor: borderColorAlpha,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: borderColorAlpha),
            borderRadius: const BorderRadius.all(Radius.circular(borderRadius)),
          ),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: borderColorAlpha),
              borderRadius: BorderRadius.circular(borderRadius)),
          errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: errorColor),
              borderRadius: BorderRadius.circular(borderRadius)),
          focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: borderColorAlpha),
              borderRadius: BorderRadius.circular(borderRadius)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: borderColorAlpha),
              borderRadius: BorderRadius.circular(borderRadius)),
          disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: secondaryColorAlpha),
              borderRadius: BorderRadius.circular(borderRadius)),
        ),
        
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: 1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: themePrimaryColor,
          primary: themePrimaryColor,
          primaryContainer: whiteColor,
          surface: themeBackgroundColor,
          secondary: themeSecondaryColor,
          shadow: shadowColorConst,
          error: errorColor,
          onPrimary: whiteColor,
        ),
      );
  }
}
