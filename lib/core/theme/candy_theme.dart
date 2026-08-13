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
  static const darkCanvas = Color(0xFF19151F);
  static const darkPaper = Color(0xFF2A2330);
  static const darkInk = Color(0xFFFFF7ED);
}

/// Shared spacing values used by the app shell and future features.
abstract final class CandySpacing {
  static const page = 24.0;
  static const compact = 12.0;
  static const cardGap = 16.0;
  static const section = 32.0;
  static const minimumTouchTarget = 48.0;
}

/// Responsive layout constraints shared by focused content surfaces.
abstract final class CandyLayout {
  static const contentMaxWidth = 560.0;
}

/// Semantic icon sizes for branded and stateful illustrations.
abstract final class CandyIconSize {
  static const hero = 64.0;
  static const status = 48.0;
  static const action = 32.0;
}

/// Shared corner-radius values used by the candy collage.
abstract final class CandyShapes {
  static const card = 20.0;
  static const poster = 16.0;
  static const pill = 999.0;
  static const gridCardRatio = 0.58;
}

abstract final class CandyImages {
  static const artworkCacheWidth = 256;
  static const posterPreviewNetworkWidth = 48;
  static const posterPreviewQuality = 35;
  static const posterPreviewBlur = 20;
  static const posterDisplayNetworkWidth = 600;
  static const posterDisplayQuality = 90;
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

/// Builds the light Material 3 theme for the app shell.
ThemeData buildCandyLightTheme() => buildCandyTheme();

/// Builds the dark Material 3 theme for the app shell.
ThemeData buildCandyDarkTheme() => buildCandyTheme(brightness: Brightness.dark);

/// Builds a Material 3 theme for the requested appearance.
ThemeData buildCandyTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = isDark
      ? const ColorScheme.dark(
          primary: CandyColors.coral,
          onPrimary: CandyColors.ink,
          secondary: CandyColors.orange,
          onSecondary: CandyColors.ink,
          tertiary: CandyColors.aqua,
          onTertiary: CandyColors.ink,
          surface: CandyColors.darkCanvas,
          onSurface: CandyColors.darkInk,
          error: CandyColors.berry,
          onError: CandyColors.ink,
        )
      : const ColorScheme.light(
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
        );
  final baseTextTheme =
      (isDark ? ThemeData.dark() : ThemeData.light()).textTheme;
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
    brightness: brightness,
    useMaterial3: true,
    scaffoldBackgroundColor: colorScheme.surface,
    colorScheme: colorScheme,
    cardTheme: CardThemeData(
      color: isDark ? CandyColors.darkPaper : CandyColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CandyShapes.card),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: isDark ? CandyColors.darkPaper : CandyColors.paper,
      modalBackgroundColor: isDark ? CandyColors.darkPaper : CandyColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CandyShapes.card),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: isDark ? CandyColors.darkPaper : CandyColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CandyShapes.card),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: CandySpacing.cardGap,
        vertical: CandySpacing.compact,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CandyShapes.card),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CandyShapes.card),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CandyShapes.card),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll<Size>(
          Size(0, CandySpacing.minimumTouchTarget),
        ),
        shape: const WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder()),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll<Size>(
          Size(0, CandySpacing.minimumTouchTarget),
        ),
        shape: const WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder()),
      ),
    ),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll<Size>(
          Size.square(CandySpacing.minimumTouchTarget),
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll<Size>(
          Size(0, CandySpacing.minimumTouchTarget),
        ),
        shape: const WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder()),
        side: WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onInverseSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CandyShapes.card),
      ),
    ),
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    extensions: <ThemeExtension<dynamic>>[
      CandyThemeTokens(
        canvas: colorScheme.surface,
        cardRadius: CandyShapes.card,
        standardMotion: CandyMotion.standard,
      ),
    ],
  );
}
