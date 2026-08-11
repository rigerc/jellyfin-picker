import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';

void main() {
  test(
    'should expose the semantic candy palette when colors are requested',
    () {
      expect(CandyColors.canvas, const Color(0xFFFFF7ED));
      expect(CandyColors.paper, const Color(0xFFFFFFFF));
      expect(CandyColors.coral, const Color(0xFFFF6B6B));
      expect(CandyColors.orange, const Color(0xFFFF9F43));
      expect(CandyColors.aqua, const Color(0xFF4ECDC4));
      expect(CandyColors.lemon, const Color(0xFFFFD166));
      expect(CandyColors.ink, const Color(0xFF2D3047));
      expect(CandyColors.mint, const Color(0xFF6BCB77));
      expect(CandyColors.berry, const Color(0xFFD1495B));
      expect(CandyColors.amber, const Color(0xFFF4A261));
    },
  );

  test(
    'should expose shared spacing shape and motion tokens when requested',
    () {
      expect(CandySpacing.page, 24);
      expect(CandyShapes.card, 20);
      expect(CandyMotion.standard, const Duration(milliseconds: 300));
    },
  );

  test('should build a material three theme with typography roles', () {
    final theme = buildCandyTheme();

    expect(theme.useMaterial3, isTrue);
    expect(theme.extension<CandyThemeTokens>(), isNotNull);
    expect(theme.colorScheme.primary, CandyColors.coral);
    expect(theme.textTheme.displaySmall?.fontFamily, CandyTypography.display);
    expect(
      theme.textTheme.displaySmall?.fontWeight,
      CandyTypography.displayWeight,
    );
    expect(theme.textTheme.bodyLarge?.fontFamily, CandyTypography.body);
    expect(theme.textTheme.bodyLarge?.height, CandyTypography.bodyLineHeight);
  });

  test('should expose installed theme tokens when the theme is requested', () {
    final theme = buildCandyTheme();
    final tokens = theme.extension<CandyThemeTokens>();

    expect(tokens?.canvas, CandyColors.canvas);
    expect(tokens?.cardRadius, CandyShapes.card);
    expect(tokens?.standardMotion, CandyMotion.standard);
  });

  test('should copy selected theme tokens when overrides are supplied', () {
    const original = CandyThemeTokens(
      canvas: CandyColors.canvas,
      cardRadius: CandyShapes.card,
      standardMotion: CandyMotion.standard,
    );

    final copied = original.copyWith(
      canvas: CandyColors.lemon,
      cardRadius: CandyShapes.pill,
    );

    expect(copied.canvas, CandyColors.lemon);
    expect(copied.cardRadius, CandyShapes.pill);
    expect(copied.standardMotion, CandyMotion.standard);
  });

  test('should interpolate theme tokens when another theme is supplied', () {
    const original = CandyThemeTokens(
      canvas: CandyColors.canvas,
      cardRadius: CandyShapes.card,
      standardMotion: CandyMotion.standard,
    );
    const target = CandyThemeTokens(
      canvas: CandyColors.lemon,
      cardRadius: CandyShapes.pill,
      standardMotion: Duration(milliseconds: 500),
    );

    final interpolated = original.lerp(target, 0.5);

    expect(
      interpolated.canvas,
      Color.lerp(CandyColors.canvas, CandyColors.lemon, 0.5),
    );
    expect(interpolated.cardRadius, 509.5);
    expect(interpolated.standardMotion, const Duration(milliseconds: 500));
  });

  test(
    'should retain tokens when interpolation receives another extension type',
    () {
      const original = CandyThemeTokens(
        canvas: CandyColors.canvas,
        cardRadius: CandyShapes.card,
        standardMotion: CandyMotion.standard,
      );

      final interpolated = original.lerp(null, 0.5);

      expect(interpolated, same(original));
    },
  );
}
