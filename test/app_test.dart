import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/app.dart';
import 'shared/app_robot.dart';
import 'shared/connection_robot.dart';
import 'shared/fake_connection_repository.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/stored_session.dart';
import 'package:jellyfin_picker/features/connection/domain/repositories/connection_repository.dart';

void main() {
  testWidgets('should render the localized app shell when English is active', (
    tester,
  ) async {
    final router = buildAppRouter();
    final robot = AppRobot(tester);

    await tester.pumpWidget(JellyfinPickerApp(router: router));
    await tester.pumpAndSettle();

    robot.expectLocalizedHomeVisible();
    router.dispose();
  });

  testWidgets('should preserve the injected router when the app rebuilds', (
    tester,
  ) async {
    final router = buildAppRouter();
    final robot = AppRobot(tester);

    await tester.pumpWidget(JellyfinPickerApp(router: router));
    await tester.pumpAndSettle();
    await tester.pumpWidget(JellyfinPickerApp(router: router));
    await tester.pumpAndSettle();

    robot.expectAppShellVisible();
    router.dispose();
  });

  testWidgets('should restore an authenticated summary and logout to form', (
    tester,
  ) async {
    final router = buildAppRouter(
      connectionRepository: FakeConnectionRepository(
        restoreResult: SessionRestored(_session()),
      ),
    );
    final robot = ConnectionRobot(tester);

    await tester.pumpWidget(JellyfinPickerApp(router: router));
    await tester.pumpAndSettle();
    robot.expectSummaryVisible();
    await robot.tapLogout();
    robot.expectSummaryAbsent();
    router.dispose();
  });

  testWidgets('should keep secrets at composition when discovery opens', (
    tester,
  ) async {
    const discoveryKey = Key('authenticated-discovery-test');
    StoredSession? receivedSession;
    final router = buildAppRouter(
      connectionRepository: FakeConnectionRepository(
        restoreResult: SessionRestored(_session()),
      ),
      authenticatedBuilder: (context, session) {
        receivedSession = session;
        return const SizedBox(key: discoveryKey);
      },
    );
    final robot = ConnectionRobot(tester);

    await tester.pumpWidget(JellyfinPickerApp(router: router));
    await tester.pumpAndSettle();
    await robot.tapExplore();

    expect(find.byKey(discoveryKey), findsOneWidget);
    expect(receivedSession?.accessToken, 'secret-token');
    router.dispose();
  });
}

StoredSession _session() => const StoredSession(
  serverUrl: 'https://example.test',
  accessToken: 'secret-token',
  userId: 'user-id',
  username: 'alice',
  deviceId: 'device-id',
);
