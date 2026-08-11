import 'package:flutter/material.dart';

/// Semantic colors for the bright candy-collage visual language.
abstract final class CandyColors {
  static const canvas = Color(0xFFFFF7ED);
  static const paper = Color(0xFFFFFFFF);
  static const coral = Color(0xFFFF6B6B);
  static const orange = Color(0xFFFF9F43);
  static const aqua = Color(0xFF4ECDC4);
  static const lemon = Color(0xFFFFD166);
  static const ink = Color(0xFF2D3047);
  static const mint = Color(0xFF6BCB77);
  static const berry = Color(0xFFD1495B);
  static const amber = Color(0xFFF4A261);
}

/// Shared spacing values used by the app shell and future features.
abstract final class CandySpacing {
  static const page = 24.0;
  static const compact = 12.0;
  static const cardGap = 16.0;
  static const section = 32.0;
  static const minimumTouchTarget = 48.0;
}

/// Shared corner-radius values used by the candy collage.
abstract final class CandyShapes {
  static const card = 20.0;
  static const poster = 16.0;
  static const pill = 999.0;
  static const gridCardRatio = 0.58;
}

abstract final class CandyImages {
  static const posterCacheWidth = 600;
}

/// Shared motion values used by transitions and feedback.
abstract final class CandyMotion {
  static const quick = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 300);
}

/// Semantic typography roles; fonts intentionally fall back when not bundled.
abstract final class CandyTypography {
  static const display = 'Fredoka';
  static const displayWeight = FontWeight.w700;
  static const body = 'Atkinson Hyperlegible';
  static const bodyLineHeight = 1.5;
}

/// Theme extension exposing semantic design tokens through [ThemeData].
@immutable
final class CandyThemeTokens extends ThemeExtension<CandyThemeTokens> {
  const CandyThemeTokens({
    required this.canvas,
    required this.cardRadius,
    required this.standardMotion,
  });

  final Color canvas;
  final double cardRadius;
  final Duration standardMotion;

  @override
  CandyThemeTokens copyWith({
    Color? canvas,
    double? cardRadius,
    Duration? standardMotion,
  }) {
    return CandyThemeTokens(
      canvas: canvas ?? this.canvas,
      cardRadius: cardRadius ?? this.cardRadius,
      standardMotion: standardMotion ?? this.standardMotion,
    );
  }

  @override
  CandyThemeTokens lerp(
    covariant ThemeExtension<CandyThemeTokens>? other,
    double t,
  ) {
    if (other is! CandyThemeTokens) {
      return this;
    }
    return CandyThemeTokens(
      canvas: Color.lerp(canvas, other.canvas, t) ?? canvas,
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      standardMotion: t < 0.5 ? standardMotion : other.standardMotion,
    );
  }
}

/// Builds the Material 3 theme for the app shell.
ThemeData buildCandyTheme() {
  final baseTextTheme = ThemeData.light().textTheme;
  final textTheme = baseTextTheme.copyWith(
    displayLarge: baseTextTheme.displayLarge?.copyWith(
      fontFamily: CandyTypography.display,
      fontWeight: CandyTypography.displayWeight,
    ),
    displayMedium: baseTextTheme.displayMedium?.copyWith(
      fontFamily: CandyTypography.display,
      fontWeight: CandyTypography.displayWeight,
    ),
    displaySmall: baseTextTheme.displaySmall?.copyWith(
      fontFamily: CandyTypography.display,
      fontWeight: CandyTypography.displayWeight,
    ),
    headlineLarge: baseTextTheme.headlineLarge?.copyWith(
      fontFamily: CandyTypography.display,
      fontWeight: CandyTypography.displayWeight,
    ),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      fontFamily: CandyTypography.display,
      fontWeight: CandyTypography.displayWeight,
    ),
    headlineSmall: baseTextTheme.headlineSmall?.copyWith(
      fontFamily: CandyTypography.display,
      fontWeight: CandyTypography.displayWeight,
    ),
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(
      fontFamily: CandyTypography.body,
      height: CandyTypography.bodyLineHeight,
    ),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      fontFamily: CandyTypography.body,
      height: CandyTypography.bodyLineHeight,
    ),
    bodySmall: baseTextTheme.bodySmall?.copyWith(
      fontFamily: CandyTypography.body,
      height: CandyTypography.bodyLineHeight,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: CandyColors.canvas,
    colorScheme: const ColorScheme.light(
      primary: CandyColors.coral,
      onPrimary: CandyColors.ink,
      secondary: CandyColors.orange,
      onSecondary: CandyColors.ink,
      tertiary: CandyColors.aqua,
      onTertiary: CandyColors.ink,
      surface: CandyColors.canvas,
      onSurface: CandyColors.ink,
      error: CandyColors.berry,
      onError: CandyColors.ink,
    ),
    textTheme: textTheme.apply(
      bodyColor: CandyColors.ink,
      displayColor: CandyColors.ink,
    ),
    extensions: const <ThemeExtension<dynamic>>[
      CandyThemeTokens(
        canvas: CandyColors.canvas,
        cardRadius: CandyShapes.card,
        standardMotion: CandyMotion.standard,
      ),
    ],
  );
}
