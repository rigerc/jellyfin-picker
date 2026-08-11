import 'package:flutter_test/flutter_test.dart';
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
  }
}
