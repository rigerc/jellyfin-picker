import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_filter.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
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

  testWidgets(
    'should fill the usable viewport when the grid has multiple rows',
    (tester) async {
      tester.view.physicalSize = const Size(360, 808);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cubit = _cubit();
      await cubit.replaceCandidates(
        List<CatalogCandidate>.generate(
          20,
          (index) => _candidate(id: 'movie-$index', name: 'Movie $index'),
        ),
      );
      final robot = DiscoveryRobot(tester);

      await _pumpPage(
        tester,
        cubit,
        topInset: CandySpacing.page,
        bottomInset: CandySpacing.page,
        bottomViewInset: 120,
      );

      robot.expectGridReachesUsableBottom(bottomInset: CandySpacing.page);
      await cubit.close();
    },
  );

  testWidgets('should fill a tall Android viewport without a keyboard inset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 923);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = _cubit();
    await cubit.replaceCandidates(
      List<CatalogCandidate>.generate(
        200,
        (index) => _candidate(id: 'movie-$index', name: 'Movie $index'),
      ),
    );
    final robot = DiscoveryRobot(tester);

    await _pumpPage(
      tester,
      cubit,
      topInset: CandySpacing.page,
      bottomInset: CandySpacing.page,
    );

    robot.expectGridReachesUsableBottom(bottomInset: CandySpacing.page);
    await cubit.close();
  });

  testWidgets(
    'should fill the screenshot-sized Android viewport without a keyboard inset',
    (tester) async {
      tester.view.physicalSize = const Size(393, 881);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cubit = _cubit();
      await cubit.replaceCandidates(
        List<CatalogCandidate>.generate(
          20,
          (index) => _candidate(id: 'movie-$index', name: 'Movie $index'),
        ),
      );
      final robot = DiscoveryRobot(tester);

      await _pumpPage(
        tester,
        cubit,
        topInset: CandySpacing.page,
        bottomInset: CandySpacing.page,
      );

      robot.expectGridReachesUsableBottom(bottomInset: CandySpacing.page);
      await cubit.close();
    },
  );

  testWidgets('should reach the final row when the tall-phone grid scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 808);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = _cubit();
    await cubit.replaceCandidates(
      List<CatalogCandidate>.generate(
        20,
        (index) => _candidate(id: 'movie-$index', name: 'Movie $index'),
      ),
    );
    final robot = DiscoveryRobot(tester);

    await _pumpPage(
      tester,
      cubit,
      topInset: CandySpacing.page,
      bottomInset: CandySpacing.page,
      bottomViewInset: 120,
    );
    await robot.scrollGridToBottom();

    robot.expectGridCandidateVisible('movie-19');
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
    robot.expectNoBlankAreaBelowDetails();
    await cubit.close();
  });

  testWidgets(
    'should avoid blank details space with a bottom inset in dark mode',
    (tester) async {
      final cubit = _cubit();
      await cubit.replaceCandidates(<CatalogCandidate>[_candidate()]);
      final robot = DiscoveryRobot(tester);

      await _pumpPage(
        tester,
        cubit,
        brightness: Brightness.dark,
        bottomInset: CandySpacing.page,
      );
      await robot.openFirstDetails();

      robot.expectNoBlankAreaBelowDetails(bottomInset: CandySpacing.page);
      await cubit.close();
    },
  );

  testWidgets('should keep long details scrollable on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[
      _candidate(overview: List<String>.filled(20, 'Long synopsis.').join(' ')),
    ]);
    final robot = DiscoveryRobot(tester);

    await _pumpPage(tester, cubit);
    await robot.openFirstDetails();

    robot.expectDetailsScrollable();
    await robot.scrollDetailsToBottom();
    robot.expectNoBlankAreaBelowDetails();
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

  testWidgets('should expose quick filters and active filter state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate()]);
    final robot = DiscoveryRobot(tester);

    await _pumpPage(tester, cubit);
    robot.expectQuickFiltersVisible();
    robot.expectFiltersInactive();
    expect(
      tester.getSemantics(find.byKey(WidgetKeys.discoveryRecentFilter)).label,
      contains('Added in last 30 days'),
    );
    expect(
      tester
          .getSemantics(find.byKey(WidgetKeys.discoveryUnwatchedFilter))
          .label,
      contains('Unwatched'),
    );
    expect(
      tester
          .getSemantics(find.byKey(WidgetKeys.discoveryFavoritesFilter))
          .label,
      contains('Favorites'),
    );
    await robot.tapRecentThirtyDays();

    expect(cubit.state.filter.isActive, isTrue);
    await tester.tap(find.byKey(WidgetKeys.discoveryUnwatchedFilter));
    await tester.pump();
    await tester.tap(find.byKey(WidgetKeys.discoveryFavoritesFilter));
    await tester.pump();
    expect(cubit.state.filter.watched, isFalse);
    expect(cubit.state.filter.favorite, isTrue);
    robot.expectFiltersActive();
    semantics.dispose();
    await cubit.close();
  });

  testWidgets('should combine search, recent, and metadata filters', (
    tester,
  ) async {
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate()]);
    final robot = DiscoveryRobot(tester);

    await _pumpPage(tester, cubit);
    await robot.applyAdvancedFilters();

    expect(cubit.state.filter.searchTerm, 'Candy');
    expect(cubit.state.filter.sort, CatalogSort.recentlyAdded);
    expect(cubit.state.filter.addedWithin, CatalogAddedWindow.thirtyDays);
    expect(cubit.state.filter.genres, <String>{'mystery'});
    expect(cubit.state.filter.decades, <int>{2020});
    expect(cubit.state.filter.officialRatings, <String>{'PG-13'});
    expect(cubit.state.filter.seriesStatuses, <CatalogSeriesStatus>{
      CatalogSeriesStatus.continuing,
    });
    await cubit.close();
  });

  testWidgets('should preserve restored maximum ratings when reapplied', (
    tester,
  ) async {
    final cubit = _cubit();
    await cubit.updateFilter(
      const CatalogFilter(maximumCommunityRating: 9, maximumCriticRating: 95),
    );
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate()]);

    await _pumpPage(tester, cubit);
    await tester.tap(find.byKey(WidgetKeys.discoveryFilterButton));
    await tester.pumpAndSettle();
    final apply = find.byKey(WidgetKeys.discoveryApplyFilters);
    await tester.scrollUntilVisible(
      apply,
      CandySpacing.section,
      scrollable: find
          .descendant(
            of: find.byKey(WidgetKeys.discoveryFilterSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(apply);
    await tester.pumpAndSettle();

    expect(cubit.state.filter.maximumCommunityRating, 9);
    expect(cubit.state.filter.maximumCriticRating, 95);
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
      _candidate(poster: _networkPoster()),
    ]);
    final robot = DiscoveryRobot(tester);

    await _pumpPage(tester, cubit);

    robot.expectProgressivePoster('movie-1');
    robot.expectGridPosterFit('movie-1', BoxFit.cover);
    await cubit.close();
  });

  testWidgets('should show the complete poster in swipe mode', (tester) async {
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[
      _candidate(poster: _networkPoster()),
    ]);
    final robot = DiscoveryRobot(tester);

    await _pumpPage(tester, cubit);
    await robot.openSwipe();

    robot.expectSwipePosterFit('movie-1', BoxFit.contain);
    await cubit.close();
  });

  testWidgets('should show the complete poster in shuffle mode', (
    tester,
  ) async {
    final cubit = _cubit();
    await cubit.replaceCandidates(<CatalogCandidate>[
      _candidate(poster: _networkPoster()),
    ]);
    final robot = DiscoveryRobot(tester);

    await _pumpPage(tester, cubit);
    await robot.openShuffle();
    await robot.reveal();

    robot.expectShufflePosterFit('movie-1', BoxFit.contain);
    await cubit.close();
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  DiscoveryCubit cubit, {
  Future<bool> Function(CatalogCandidate candidate)? onToggleFavorite,
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = false,
  Brightness brightness = Brightness.light,
  double topInset = 0,
  double bottomInset = 0,
  double bottomViewInset = 0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildCandyTheme(brightness: brightness),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: textScaler,
          disableAnimations: disableAnimations,
          padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
          viewPadding: EdgeInsets.only(top: topInset, bottom: bottomInset),
          viewInsets: EdgeInsets.only(bottom: bottomViewInset),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      home: DiscoveryPage(cubit: cubit, onToggleFavorite: onToggleFavorite),
    ),
  );
  await tester.pump();
}

DiscoveryCubit _cubit() => DiscoveryCubit(
  store: ImmediateDiscoveryStore(),
  scopeKey: 'server/user',
  selector: FakeDiscoverySelector('movie-1'),
);

CatalogCandidate _candidate({
  String id = 'movie-1',
  String name = 'Candy Comet',
  CatalogImage? poster,
  String overview = 'A warm mystery in space.',
}) => CatalogCandidate(
  id: id,
  name: name,
  mediaType: CatalogMediaType.movie,
  year: 2024,
  runtimeMinutes: 112,
  genres: const <String>{'mystery', 'science fiction'},
  communityRating: 8.4,
  criticRating: 91,
  officialRating: 'PG-13',
  status: 'Returning Series',
  overview: overview,
  cast: const <String>['Ava Actor', 'Sam Star'],
  watched: false,
  favorite: false,
  poster: poster ?? const CatalogImage.fallback(),
  backdrop: const CatalogImage.fallback(),
);

CatalogImage _networkPoster() => CatalogImage(
  uri: Uri.parse(
    'https://example.test/Items/movie-1/Images/Primary?tag=poster',
  ),
  isFallback: false,
  aspectRatio: 0.67,
);
