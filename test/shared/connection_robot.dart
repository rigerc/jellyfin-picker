import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';

final class ConnectionRobot {
  const ConnectionRobot(this.tester);

  final WidgetTester tester;

  void expectFormVisible() {
    expect(find.byKey(WidgetKeys.connectionForm), findsOneWidget);
  }

  void expectAccessibleFieldsVisible() {
    expect(find.byKey(WidgetKeys.connectionUrlField), findsOneWidget);
    expect(find.byKey(WidgetKeys.connectionUsernameField), findsOneWidget);
    expect(find.byKey(WidgetKeys.connectionPasswordField), findsOneWidget);
    expect(find.byKey(WidgetKeys.connectionSubmitButton), findsOneWidget);
  }

  void expectPrivateHttpWarningVisible() {
    expect(
      find.byKey(WidgetKeys.connectionConfirmPrivateHttpButton),
      findsOneWidget,
    );
  }

  void expectPrivateHttpWarningAbsent() {
    expect(
      find.byKey(WidgetKeys.connectionConfirmPrivateHttpButton),
      findsNothing,
    );
  }

  Future<void> submitPrivateHttpCredentials() async {
    await tester.enterText(
      find.byKey(WidgetKeys.connectionUrlField),
      'http://192.168.1.20:8096',
    );
    await tester.enterText(
      find.byKey(WidgetKeys.connectionUsernameField),
      'alice',
    );
    await tester.enterText(
      find.byKey(WidgetKeys.connectionPasswordField),
      'secret',
    );
    await tester.tap(find.byKey(WidgetKeys.connectionSubmitButton));
    await tester.pumpAndSettle();
  }

  Future<void> confirmPrivateHttpAndExpectPasswordCleared() async {
    final passwordController = tester
        .widget<TextField>(find.byKey(WidgetKeys.connectionPasswordField))
        .controller;
    await tester.tap(find.byKey(WidgetKeys.connectionConfirmPrivateHttpButton));
    await tester.pumpAndSettle();
    expect(passwordController?.text, isEmpty);
  }

  void expectErrorVisible() {
    expect(find.byKey(WidgetKeys.connectionError), findsOneWidget);
  }

  void expectSummaryVisible() {
    expect(find.byKey(WidgetKeys.connectionSummary), findsOneWidget);
  }

  void expectFormAbsent() {
    expect(find.byKey(WidgetKeys.connectionForm), findsNothing);
  }

  void expectSummaryAbsent() {
    expect(find.byKey(WidgetKeys.connectionSummary), findsNothing);
  }

  Future<void> tapLogout() async {
    await tester.tap(find.byKey(WidgetKeys.connectionLogoutButton));
    await tester.pumpAndSettle();
  }

  Future<void> tapExplore() async {
    await tester.tap(find.byKey(WidgetKeys.connectionExploreButton));
    await tester.pumpAndSettle();
  }

  Future<void> submitCredentials() async {
    await tester.enterText(
      find.byKey(WidgetKeys.connectionUrlField),
      'https://example.test',
    );
    await tester.enterText(
      find.byKey(WidgetKeys.connectionUsernameField),
      'alice',
    );
    await tester.enterText(
      find.byKey(WidgetKeys.connectionPasswordField),
      'secret',
    );
    await tester.tap(find.byKey(WidgetKeys.connectionSubmitButton));
    await tester.pumpAndSettle();
  }

  void expectPasswordCleared() {
    final field = tester.widget<TextField>(
      find.byKey(WidgetKeys.connectionPasswordField),
    );
    expect(field.controller?.text, isEmpty);
  }
}
