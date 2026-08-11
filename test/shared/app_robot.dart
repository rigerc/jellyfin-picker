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
    expect(find.text('Jellyfin Picker'), findsOneWidget);
    expect(find.text('Pick something great'), findsOneWidget);
    expect(find.byIcon(Icons.movie_filter_rounded), findsOneWidget);
  }

  void expectSystemThemeConfigured() {
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(app.darkTheme, isNotNull);
  }
}
