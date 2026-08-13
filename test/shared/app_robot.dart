import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';

final class AppRobot {
  const AppRobot(this.tester);

  final WidgetTester tester;

  void expectAppShellVisible() {
    expect(find.byKey(WidgetKeys.appShell), findsOneWidget);
  }

  void expectLocalizedHomeVisible() {
    expectAppShellVisible();
    expect(find.text('Jellyfilter'), findsOneWidget);
    expect(find.text('Pick something great'), findsOneWidget);
    _expectAssetImage('docs/icons/app-icon.png');
  }

  void expectSystemThemeConfigured() {
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(app.darkTheme, isNotNull);
  }

  void _expectAssetImage(String assetName) {
    final images = tester.widgetList<Image>(
      find.descendant(
        of: find.byKey(WidgetKeys.appShell),
        matching: find.byType(Image),
      ),
    );
    expect(images.map((image) => _assetName(image.image)), contains(assetName));
  }

  String? _assetName(ImageProvider provider) => switch (provider) {
    AssetImage(:final assetName) => assetName,
    ResizeImage(imageProvider: AssetImage(:final assetName)) => assetName,
    _ => null,
  };
}
