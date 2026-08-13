import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';

void main() {
  test(
    'should expose violet and blue brand colors when palette is requested',
    () {
      final brandColors = (
        primary: CandyColors.primary,
        secondary: CandyColors.secondaryBrand,
      );

      expect(brandColors, (
        primary: const Color(0xFF8B5CF6),
        secondary: const Color(0xFF4257CE),
      ));
    },
  );

  test('should use violet and blue brand colors in both brightness modes', () {
    final themes = [buildCandyLightTheme(), buildCandyDarkTheme()];

    final brandRoles = [
      for (final theme in themes)
        (
          brightness: theme.brightness,
          primary: theme.colorScheme.primary,
          secondary: theme.colorScheme.secondary,
        ),
    ];

    expect(brandRoles, [
      (
        brightness: Brightness.light,
        primary: CandyColors.primary,
        secondary: CandyColors.secondaryBrand,
      ),
      (
        brightness: Brightness.dark,
        primary: CandyColors.primary,
        secondary: CandyColors.secondaryBrand,
      ),
    ]);
  });

  test(
    'should expose the semantic signature palette when colors are requested',
    () {
      final palette = (
        primary: CandyColors.primary,
        secondaryBrand: CandyColors.secondaryBrand,
        accent: CandyColors.accent,
        softAccent: CandyColors.softAccent,
        warmAccent: CandyColors.warmAccent,
        surface: CandyColors.surface,
        background: CandyColors.background,
        onDark: CandyColors.onDark,
        contrastInk: CandyColors.contrastInk,
      );

      expect(palette, (
        primary: const Color(0xFF8B5CF6),
        secondaryBrand: const Color(0xFF4257CE),
        accent: const Color(0xFF7FE6D2),
        softAccent: const Color(0xFFC9AEEE),
        warmAccent: const Color(0xFFF2A6C2),
        surface: const Color(0xFF211A48),
        background: const Color(0xFF141033),
        onDark: const Color(0xFFF0EAFB),
        contrastInk: const Color(0xFF000000),
      ));
    },
  );

  test('should map semantic palette roles in both brightness modes', () {
    final themes = [buildCandyLightTheme(), buildCandyDarkTheme()];

    final semanticRoles = [
      for (final theme in themes)
        (
          onPrimary: theme.colorScheme.onPrimary,
          onSecondary: theme.colorScheme.onSecondary,
          tertiary: theme.colorScheme.tertiary,
          onTertiary: theme.colorScheme.onTertiary,
          tertiaryContainer: theme.colorScheme.tertiaryContainer,
          onTertiaryContainer: theme.colorScheme.onTertiaryContainer,
          error: theme.colorScheme.error,
          onError: theme.colorScheme.onError,
          errorContainer: theme.colorScheme.errorContainer,
          onErrorContainer: theme.colorScheme.onErrorContainer,
          secondaryContainer: theme.colorScheme.secondaryContainer,
          onSecondaryContainer: theme.colorScheme.onSecondaryContainer,
          surface: theme.colorScheme.surface,
          onSurface: theme.colorScheme.onSurface,
          onSurfaceVariant: theme.colorScheme.onSurfaceVariant,
          outlineVariant: theme.colorScheme.outlineVariant,
          inverseSurface: theme.colorScheme.inverseSurface,
          onInverseSurface: theme.colorScheme.onInverseSurface,
          surfaceContainerHighest: theme.colorScheme.surfaceContainerHighest,
          bodyColor: theme.textTheme.bodyLarge?.color,
        ),
    ];

    expect(semanticRoles, [
      (
        onPrimary: CandyColors.contrastInk,
        onSecondary: CandyColors.onDark,
        tertiary: CandyColors.accent,
        onTertiary: CandyColors.background,
        tertiaryContainer: CandyColors.softAccent,
        onTertiaryContainer: CandyColors.background,
        error: CandyColors.warmAccent,
        onError: CandyColors.background,
        errorContainer: CandyColors.warmAccent,
        onErrorContainer: CandyColors.background,
        secondaryContainer: CandyColors.secondaryBrand,
        onSecondaryContainer: CandyColors.onDark,
        surface: CandyColors.surface,
        onSurface: CandyColors.onDark,
        onSurfaceVariant: CandyColors.softAccent,
        outlineVariant: CandyColors.softAccent,
        inverseSurface: CandyColors.surface,
        onInverseSurface: CandyColors.onDark,
        surfaceContainerHighest: CandyColors.surface,
        bodyColor: CandyColors.onDark,
      ),
      (
        onPrimary: CandyColors.contrastInk,
        onSecondary: CandyColors.onDark,
        tertiary: CandyColors.accent,
        onTertiary: CandyColors.background,
        tertiaryContainer: CandyColors.softAccent,
        onTertiaryContainer: CandyColors.background,
        error: CandyColors.warmAccent,
        onError: CandyColors.background,
        errorContainer: CandyColors.warmAccent,
        onErrorContainer: CandyColors.background,
        secondaryContainer: CandyColors.secondaryBrand,
        onSecondaryContainer: CandyColors.onDark,
        surface: CandyColors.surface,
        onSurface: CandyColors.onDark,
        onSurfaceVariant: CandyColors.softAccent,
        outlineVariant: CandyColors.softAccent,
        inverseSurface: CandyColors.surface,
        onInverseSurface: CandyColors.onDark,
        surfaceContainerHighest: CandyColors.surface,
        bodyColor: CandyColors.onDark,
      ),
    ]);
  });

  test('should style selected filter controls in both brightness modes', () {
    final themes = [buildCandyLightTheme(), buildCandyDarkTheme()];
    final selectedStates = <WidgetState>{WidgetState.selected};
    final unselectedStates = <WidgetState>{};

    final selectedStyles = [
      for (final theme in themes)
        (
          filterBackground: theme.chipTheme.color?.resolve(selectedStates),
          filterForeground: WidgetStateProperty.resolveAs<Color?>(
            theme.chipTheme.labelStyle?.color,
            selectedStates,
          ),
          filterUnselectedForeground: WidgetStateProperty.resolveAs<Color?>(
            theme.chipTheme.labelStyle?.color,
            unselectedStates,
          ),
          filterCheckmark: theme.chipTheme.checkmarkColor,
          segmentedBackground: theme.segmentedButtonTheme.style?.backgroundColor
              ?.resolve(selectedStates),
          segmentedForeground: theme.segmentedButtonTheme.style?.foregroundColor
              ?.resolve(selectedStates),
          segmentedUnselectedForeground: theme
              .segmentedButtonTheme
              .style
              ?.foregroundColor
              ?.resolve(unselectedStates),
          minimumSize: theme.segmentedButtonTheme.style?.minimumSize?.resolve(
            selectedStates,
          ),
          usesStadiumShape:
              theme.segmentedButtonTheme.style?.shape?.resolve(selectedStates)
                  is StadiumBorder,
        ),
    ];

    expect(selectedStyles, [
      (
        filterBackground: CandyColors.primary,
        filterForeground: CandyColors.contrastInk,
        filterUnselectedForeground: CandyColors.onDark,
        filterCheckmark: CandyColors.contrastInk,
        segmentedBackground: CandyColors.primary,
        segmentedForeground: CandyColors.contrastInk,
        segmentedUnselectedForeground: CandyColors.onDark,
        minimumSize: const Size(0, CandySpacing.minimumTouchTarget),
        usesStadiumShape: true,
      ),
      (
        filterBackground: CandyColors.primary,
        filterForeground: CandyColors.contrastInk,
        filterUnselectedForeground: CandyColors.onDark,
        filterCheckmark: CandyColors.contrastInk,
        segmentedBackground: CandyColors.primary,
        segmentedForeground: CandyColors.contrastInk,
        segmentedUnselectedForeground: CandyColors.onDark,
        minimumSize: const Size(0, CandySpacing.minimumTouchTarget),
        usesStadiumShape: true,
      ),
    ]);
  });

  test('should style persistent mode navigation in both brightness modes', () {
    final themes = [buildCandyLightTheme(), buildCandyDarkTheme()];

    final navigationStyles = [
      for (final theme in themes)
        (
          background: theme.navigationBarTheme.backgroundColor,
          indicator: theme.navigationBarTheme.indicatorColor,
          height: theme.navigationBarTheme.height,
        ),
    ];

    expect(navigationStyles, [
      (
        background: CandyColors.surface,
        indicator: CandyColors.primary,
        height: CandySpacing.minimumTouchTarget + CandySpacing.compact * 2,
      ),
      (
        background: CandyColors.surface,
        indicator: CandyColors.primary,
        height: CandySpacing.minimumTouchTarget + CandySpacing.compact * 2,
      ),
    ]);
  });

  test('should use background canvas and raised surface in both modes', () {
    final themes = [buildCandyLightTheme(), buildCandyDarkTheme()];

    final surfaces = [
      for (final theme in themes)
        (
          scaffold: theme.scaffoldBackgroundColor,
          card: theme.cardTheme.color,
          bottomSheet: theme.bottomSheetTheme.backgroundColor,
          modalBottomSheet: theme.bottomSheetTheme.modalBackgroundColor,
          dialog: theme.dialogTheme.backgroundColor,
        ),
    ];

    expect(surfaces, [
      (
        scaffold: CandyColors.background,
        card: CandyColors.surface,
        bottomSheet: CandyColors.surface,
        modalBottomSheet: CandyColors.surface,
        dialog: CandyColors.surface,
      ),
      (
        scaffold: CandyColors.background,
        card: CandyColors.surface,
        bottomSheet: CandyColors.surface,
        modalBottomSheet: CandyColors.surface,
        dialog: CandyColors.surface,
      ),
    ]);
  });

  test(
    'should expose shared spacing shape and motion tokens when requested',
    () {
      expect(CandySpacing.page, 24);
      expect(CandyShapes.card, 20);
      expect(CandyMotion.standard, const Duration(milliseconds: 300));
      expect(CandyLayout.contentMaxWidth, 560);
      expect(CandyIconSize.hero, 64);
      expect(CandyIconSize.status, 48);
    },
  );

  test('should build a material three theme with typography roles', () {
    final theme = buildCandyTheme();

    expect(theme.useMaterial3, isTrue);
    expect(theme.extension<CandyThemeTokens>(), isNotNull);
    expect(theme.colorScheme.primary, CandyColors.primary);
    expect(theme.textTheme.displaySmall?.fontFamily, CandyTypography.display);
    expect(
      theme.textTheme.displaySmall?.fontWeight,
      CandyTypography.displayWeight,
    );
    expect(theme.textTheme.bodyLarge?.fontFamily, CandyTypography.body);
    expect(theme.textTheme.bodyLarge?.height, CandyTypography.bodyLineHeight);
  });

  test('should style primary controls through the shared component theme', () {
    final theme = buildCandyLightTheme();
    final states = <WidgetState>{};

    expect(theme.inputDecorationTheme.filled, isTrue);
    expect(
      theme.filledButtonTheme.style?.minimumSize?.resolve(states)?.height,
      CandySpacing.minimumTouchTarget,
    );
    expect(
      theme.iconButtonTheme.style?.minimumSize?.resolve(states)?.width,
      CandySpacing.minimumTouchTarget,
    );
    expect(theme.segmentedButtonTheme.style, isNotNull);
  });

  test('should build a dark material three theme with dark semantic roles', () {
    final theme = buildCandyDarkTheme();

    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.brightness, Brightness.dark);
    expect(theme.colorScheme.surface, CandyColors.surface);
    expect(theme.colorScheme.onSurface, CandyColors.onDark);
    expect(theme.scaffoldBackgroundColor, CandyColors.background);
    expect(theme.textTheme.bodyLarge?.color, CandyColors.onDark);
  });

  test(
    'should preserve the light theme through the explicit light builder',
    () {
      final theme = buildCandyLightTheme();

      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.surface, CandyColors.surface);
      expect(theme.colorScheme.onSurface, CandyColors.onDark);
      expect(theme.scaffoldBackgroundColor, CandyColors.background);
    },
  );

  test('should expose installed theme tokens when the theme is requested', () {
    final theme = buildCandyTheme();
    final tokens = theme.extension<CandyThemeTokens>();

    expect(tokens?.canvas, CandyColors.background);
    expect(tokens?.cardRadius, CandyShapes.card);
    expect(tokens?.standardMotion, CandyMotion.standard);
  });

  test('should copy selected theme tokens when overrides are supplied', () {
    const original = CandyThemeTokens(
      canvas: CandyColors.background,
      cardRadius: CandyShapes.card,
      standardMotion: CandyMotion.standard,
    );

    final copied = original.copyWith(
      canvas: CandyColors.softAccent,
      cardRadius: CandyShapes.pill,
    );

    expect(copied.canvas, CandyColors.softAccent);
    expect(copied.cardRadius, CandyShapes.pill);
    expect(copied.standardMotion, CandyMotion.standard);
  });

  test('should interpolate theme tokens when another theme is supplied', () {
    const original = CandyThemeTokens(
      canvas: CandyColors.background,
      cardRadius: CandyShapes.card,
      standardMotion: CandyMotion.standard,
    );
    const target = CandyThemeTokens(
      canvas: CandyColors.softAccent,
      cardRadius: CandyShapes.pill,
      standardMotion: Duration(milliseconds: 500),
    );

    final interpolated = original.lerp(target, 0.5);

    expect(
      interpolated.canvas,
      Color.lerp(CandyColors.background, CandyColors.softAccent, 0.5),
    );
    expect(interpolated.cardRadius, 509.5);
    expect(interpolated.standardMotion, const Duration(milliseconds: 500));
  });

  test(
    'should retain tokens when interpolation receives another extension type',
    () {
      const original = CandyThemeTokens(
        canvas: CandyColors.background,
        cardRadius: CandyShapes.card,
        standardMotion: CandyMotion.standard,
      );

      final interpolated = original.lerp(null, 0.5);

      expect(interpolated, same(original));
    },
  );
}
