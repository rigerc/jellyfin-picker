import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jellyfin_picker/app.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/stored_session.dart';
import 'package:jellyfin_picker/features/connection/domain/repositories/connection_repository.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_snapshot.dart';
import 'package:jellyfin_picker/features/discovery/domain/repositories/discovery_store.dart';
import 'package:jellyfin_picker/features/discovery/presentation/discovery_page.dart';

import '../test/shared/discovery_robot.dart';
import '../test/shared/fake_connection_repository.dart';
import '../test/shared/fake_discovery_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('should restore and explore every discovery mode', (
    tester,
  ) async {
    final discoveryCubit = DiscoveryCubit(
      store: _MemoryDiscoveryStore(),
      scopeKey: 'server/user',
      selector: FakeDiscoverySelector('movie-1'),
    );
    await discoveryCubit.replaceCandidates(<CatalogCandidate>[_candidate()]);
    final router = buildAppRouter(
      connectionRepository: FakeConnectionRepository(
        restoreResult: const SessionRestored(_session),
      ),
      authenticatedBuilder: (context, session) =>
          DiscoveryPage(cubit: discoveryCubit),
    );
    final discovery = DiscoveryRobot(tester);

    await tester.pumpWidget(JellyfilterApp(router: router));
    await tester.pumpAndSettle();
    discovery.expectPeerModesVisible();
    discovery.expectGridVisible();
    await discovery.openSwipe();
    discovery.expectSwipeVisible();
    await discovery.openShuffle();
    await discovery.reveal();
    discovery.expectCandidateVisible('Candy Comet');

    await discoveryCubit.close();
    router.dispose();
  });

  testWidgets('should apply and reset accessible discovery quick filters', (
    tester,
  ) async {
    final discoveryCubit = DiscoveryCubit(
      store: _MemoryDiscoveryStore(),
      scopeKey: 'server/user',
      selector: FakeDiscoverySelector('movie-1'),
    );
    await discoveryCubit.replaceCandidates(<CatalogCandidate>[_candidate()]);
    final router = buildAppRouter(
      connectionRepository: FakeConnectionRepository(
        restoreResult: const SessionRestored(_session),
      ),
      authenticatedBuilder: (context, session) =>
          DiscoveryPage(cubit: discoveryCubit),
    );
    final discovery = DiscoveryRobot(tester);

    await tester.pumpWidget(JellyfilterApp(router: router));
    await tester.pumpAndSettle();
    discovery.expectQuickFiltersVisible();
    await discovery.tapRecentThirtyDays();
    discovery.expectFiltersActive();

    await discovery.openFilters();
    await discovery.tapResetFilters();
    discovery.expectFiltersInactive();

    await discoveryCubit.close();
    router.dispose();
  });
}

const _session = StoredSession(
  serverUrl: 'https://example.test',
  accessToken: 'secret-token',
  userId: 'user-id',
  username: 'alice',
  deviceId: 'device-id',
);

CatalogCandidate _candidate() => const CatalogCandidate(
  id: 'movie-1',
  name: 'Candy Comet',
  mediaType: CatalogMediaType.movie,
  favorite: false,
  poster: CatalogImage.fallback(),
  backdrop: CatalogImage.fallback(),
);

final class _MemoryDiscoveryStore implements DiscoveryStore {
  DiscoverySnapshot? snapshot;

  @override
  Future<void> clear(String scope) async => snapshot = null;

  @override
  Future<DiscoverySnapshot?> read(String scope) async => snapshot;

  @override
  Future<void> write(String scope, DiscoverySnapshot value) async {
    snapshot = value;
  }
}
