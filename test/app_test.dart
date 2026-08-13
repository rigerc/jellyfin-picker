import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/app.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/stored_session.dart';
import 'package:jellyfin_picker/features/connection/domain/repositories/connection_repository.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/features/discovery/presentation/discovery_page.dart';

import 'shared/app_robot.dart';
import 'shared/connection_robot.dart';
import 'shared/discovery_robot.dart';
import 'shared/fake_connection_repository.dart';
import 'shared/fake_discovery_store.dart';

void main() {
  testWidgets('should render the localized app shell when English is active', (
    tester,
  ) async {
    final router = buildAppRouter();
    final robot = AppRobot(tester);

    await tester.pumpWidget(JellyfilterApp(router: router));
    await tester.pumpAndSettle();

    robot.expectLocalizedHomeVisible();
    router.dispose();
  });

  testWidgets('should preserve the injected router when the app rebuilds', (
    tester,
  ) async {
    final router = buildAppRouter();
    final robot = AppRobot(tester);

    await tester.pumpWidget(JellyfilterApp(router: router));
    await tester.pumpAndSettle();
    await tester.pumpWidget(JellyfilterApp(router: router));
    await tester.pumpAndSettle();

    robot.expectAppShellVisible();
    router.dispose();
  });

  testWidgets('should follow the system appearance by default', (tester) async {
    final router = buildAppRouter();
    final robot = AppRobot(tester);

    await tester.pumpWidget(JellyfilterApp(router: router));

    robot.expectSystemThemeConfigured();

    router.dispose();
  });

  testWidgets('should enter discovery when a valid session is restored', (
    tester,
  ) async {
    const discoveryKey = Key('restored-discovery-test');
    final router = buildAppRouter(
      connectionRepository: FakeConnectionRepository(
        restoreResult: SessionRestored(_session()),
      ),
      authenticatedBuilder: (context, session) =>
          const SizedBox(key: discoveryKey),
    );
    final robot = ConnectionRobot(tester);

    await tester.pumpWidget(JellyfilterApp(router: router));
    await tester.pumpAndSettle();
    robot.expectSummaryAbsent();
    expect(find.byKey(discoveryKey), findsOneWidget);
    router.dispose();
  });

  testWidgets('should show the connection form when no session is stored', (
    tester,
  ) async {
    final router = buildAppRouter(
      connectionRepository: FakeConnectionRepository(),
    );
    final robot = ConnectionRobot(tester);

    await tester.pumpWidget(JellyfilterApp(router: router));
    await tester.pumpAndSettle();

    robot.expectFormVisible();
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

    await tester.pumpWidget(JellyfilterApp(router: router));
    await tester.pumpAndSettle();

    expect(find.byKey(discoveryKey), findsOneWidget);
    expect(receivedSession?.accessToken, 'secret-token');
    router.dispose();
  });

  testWidgets('should fill a tall Android viewport through the app router', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 923);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = DiscoveryCubit(
      store: ImmediateDiscoveryStore(),
      scopeKey: 'server/user',
      selector: FakeDiscoverySelector('movie-0'),
    );
    await cubit.replaceCandidates(
      List<CatalogCandidate>.generate(20, _candidate),
    );
    addTearDown(cubit.close);
    final router = buildAppRouter(
      connectionRepository: FakeConnectionRepository(
        restoreResult: SessionRestored(_session()),
      ),
      authenticatedBuilder: (context, session) => DiscoveryPage(cubit: cubit),
    );
    addTearDown(router.dispose);
    final discoveryRobot = DiscoveryRobot(tester);

    await tester.pumpWidget(JellyfilterApp(router: router));
    await tester.pumpAndSettle();

    discoveryRobot.expectGridMeetsModeNavigation();
  });
}

StoredSession _session() => const StoredSession(
  serverUrl: 'https://example.test',
  accessToken: 'secret-token',
  userId: 'user-id',
  username: 'alice',
  deviceId: 'device-id',
);

CatalogCandidate _candidate(int index) => CatalogCandidate(
  id: 'movie-$index',
  name: 'Movie $index',
  mediaType: CatalogMediaType.movie,
  poster: const CatalogImage.fallback(),
  backdrop: const CatalogImage.fallback(),
);
