import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_snapshot.dart';
import 'package:jellyfin_picker/features/discovery/domain/repositories/discovery_store.dart';
import 'package:jellyfin_picker/features/discovery/presentation/discovery_page.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

import '../../../shared/discovery_robot.dart';
import '../../../shared/fake_discovery_store.dart';

void main() {
  testWidgets('should preserve the shared session across all peer modes', (
    tester,
  ) async {
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate()]);
    final robot = DiscoveryRobot(tester);

    await _pumpPage(tester, cubit);
    robot.expectPeerModesVisible();
    robot.expectGridVisible();
    await robot.openSwipe();
    robot.expectSwipeVisible();
    robot.expectCandidateVisible('Candy Comet');
    await robot.openShuffle();
    robot.expectShuffleVisible();
    await robot.reveal();
    robot.expectCandidateVisible('Candy Comet');

    expect(cubit.state.candidates.single.id, 'movie-1');
    await cubit.close();
  });

  testWidgets('should show balanced localized details when a title opens', (
    tester,
  ) async {
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate()]);
    final robot = DiscoveryRobot(tester);

    await _pumpPage(tester, cubit);
    await robot.openFirstDetails();

    robot.expectDetailsVisible();
    await cubit.close();
  });

  testWidgets('should synchronize a favorite without changing decisions', (
    tester,
  ) async {
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate()]);
    final robot = DiscoveryRobot(tester);
    var calls = 0;

    await _pumpPage(
      tester,
      cubit,
      onToggleFavorite: (candidate) async {
        calls++;
        return true;
      },
    );
    await robot.toggleFirstFavorite();

    expect(calls, 1);
    expect(cubit.state.candidates.single.favorite, isTrue);
    expect(cubit.state.likedIds, isEmpty);
    expect(cubit.state.rejectedIds, isEmpty);
    await cubit.close();
  });

  testWidgets('should apply balanced filters to the shared session', (
    tester,
  ) async {
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate()]);
    final robot = DiscoveryRobot(tester);

    await _pumpPage(tester, cubit);
    await robot.filterToMovies();

    expect(cubit.state.filter.mediaTypes, <CatalogMediaType>{
      CatalogMediaType.movie,
    });
    await cubit.close();
  });

  testWidgets('should meet mobile accessibility guidelines', (tester) async {
    final semantics = tester.ensureSemantics();
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate()]);

    await _pumpPage(tester, cubit);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
    await cubit.close();
  });

  testWidgets('should save a named filter preset locally', (tester) async {
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate()]);
    final robot = DiscoveryRobot(tester);

    await _pumpPage(tester, cubit);
    await robot.savePreset('Movie night');

    expect(cubit.state.presets.keys, contains('Movie night'));
    await cubit.close();
  });

  testWidgets('should adapt at large text in both phone orientations', (
    tester,
  ) async {
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate()]);
    final robot = DiscoveryRobot(tester);

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpPage(tester, cubit, textScaler: const TextScaler.linear(2));
    robot.expectNoLayoutException();

    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpAndSettle();
    robot.expectNoLayoutException();
    await cubit.close();
  });

  testWidgets('should disable gesture motion when reduced motion is active', (
    tester,
  ) async {
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate()]);
    final robot = DiscoveryRobot(tester);

    await _pumpPage(tester, cubit, disableAnimations: true);
    await robot.openSwipe();

    final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
    expect(dismissible.movementDuration, Duration.zero);
    expect(dismissible.resizeDuration, Duration.zero);
    await cubit.close();
  });

  testWidgets('should animate discovery mode changes when motion is enabled', (
    tester,
  ) async {
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate()]);
    final robot = DiscoveryRobot(tester);

    await _pumpPage(tester, cubit);

    robot.expectModeTransitionDuration(CandyMotion.standard);
    await cubit.close();
  });

  testWidgets('should remove mode animation when reduced motion is active', (
    tester,
  ) async {
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate()]);
    final robot = DiscoveryRobot(tester);

    await _pumpPage(tester, cubit, disableAnimations: true);

    robot.expectModeTransitionDuration(Duration.zero);
    await cubit.close();
  });

  testWidgets('should animate a newly revealed shuffle candidate', (
    tester,
  ) async {
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate()]);
    final robot = DiscoveryRobot(tester);

    await _pumpPage(tester, cubit);
    await robot.openShuffle();

    robot.expectRevealTransitionDuration(CandyMotion.standard);
    await cubit.close();
  });

  testWidgets('should give discovery cards tactile press feedback', (
    tester,
  ) async {
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate()]);
    final robot = DiscoveryRobot(tester);

    await _pumpPage(tester, cubit);

    robot.expectCandidateUsesPressBounce('movie-1');
    await cubit.close();
  });

  testWidgets('should group discovery controls on a themed header surface', (
    tester,
  ) async {
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate()]);
    final robot = DiscoveryRobot(tester);

    await _pumpPage(tester, cubit);

    robot.expectThemedHeaderVisible();
    await cubit.close();
  });

  testWidgets('should present discovery as a spacious cinema marquee', (
    tester,
  ) async {
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate()]);
    final robot = DiscoveryRobot(tester);

    await _pumpPage(tester, cubit);

    robot.expectCinemaMarquee(candidateCount: 1);
    await cubit.close();
  });

  testWidgets('should separate filter select fields clearly', (tester) async {
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate()]);
    final robot = DiscoveryRobot(tester);

    await _pumpPage(tester, cubit, textScaler: const TextScaler.linear(2));
    await robot.openFiltersAtSelects();

    robot.expectFilterSelectSpacing(CandySpacing.compact);
    await cubit.close();
  });

  testWidgets('should progressively load bounded blurred poster previews', (
    tester,
  ) async {
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[
      _candidate(
        poster: CatalogImage(
          uri: Uri.parse(
            'https://example.test/Items/movie-1/Images/Primary?tag=poster',
          ),
          isFallback: false,
          aspectRatio: 0.67,
        ),
      ),
    ]);
    final robot = DiscoveryRobot(tester);

    await _pumpPage(tester, cubit);

    robot.expectProgressivePoster('movie-1');
    await cubit.close();
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  DiscoveryCubit cubit, {
  Future<bool> Function(CatalogCandidate candidate)? onToggleFavorite,
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildCandyTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: textScaler,
          disableAnimations: disableAnimations,
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      home: DiscoveryPage(cubit: cubit, onToggleFavorite: onToggleFavorite),
    ),
  );
  await tester.pump();
}

DiscoveryCubit _cubit() => DiscoveryCubit(
  store: _ImmediateDiscoveryStore(),
  scopeKey: 'server/user',
  selector: FakeDiscoverySelector('movie-1'),
);

final class _ImmediateDiscoveryStore implements DiscoveryStore {
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

CatalogCandidate _candidate({CatalogImage? poster}) => CatalogCandidate(
  id: 'movie-1',
  name: 'Candy Comet',
  mediaType: CatalogMediaType.movie,
  year: 2024,
  runtimeMinutes: 112,
  genres: const <String>{'mystery', 'science fiction'},
  communityRating: 8.4,
  criticRating: 91,
  officialRating: 'PG-13',
  status: 'Returning Series',
  overview: 'A warm mystery in space.',
  cast: const <String>['Ava Actor', 'Sam Star'],
  watched: false,
  favorite: false,
  poster: poster ?? const CatalogImage.fallback(),
  backdrop: const CatalogImage.fallback(),
);
