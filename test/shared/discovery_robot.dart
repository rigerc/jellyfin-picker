import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/core/widgets/candy_bounce.dart';

final class DiscoveryRobot {
  const DiscoveryRobot(this.tester);

  final WidgetTester tester;

  void expectPeerModesVisible() {
    expect(find.byKey(WidgetKeys.discoveryGridMode), findsOneWidget);
    expect(find.byKey(WidgetKeys.discoverySwipeMode), findsOneWidget);
    expect(find.byKey(WidgetKeys.discoveryShuffleMode), findsOneWidget);
  }

  void expectGridVisible() {
    expect(find.byKey(WidgetKeys.discoveryGrid), findsOneWidget);
  }

  void expectQuickFiltersVisible() {
    expect(find.byKey(WidgetKeys.discoveryRecentFilter), findsOneWidget);
    expect(find.byKey(WidgetKeys.discoveryUnwatchedFilter), findsOneWidget);
    expect(find.byKey(WidgetKeys.discoveryFavoritesFilter), findsOneWidget);
  }

  void expectFiltersInactive() {
    expect(find.byKey(WidgetKeys.discoveryActiveFilterIndicator), findsNothing);
  }

  void expectFiltersActive() {
    expect(
      find.byKey(WidgetKeys.discoveryActiveFilterIndicator),
      findsOneWidget,
    );
  }

  Future<void> tapRecentThirtyDays() async {
    await tester.tap(find.byKey(WidgetKeys.discoveryRecentFilter));
    await tester.pump();
  }

  Future<void> openFilters() async {
    await tester.tap(find.byKey(WidgetKeys.discoveryFilterButton));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(WidgetKeys.discoveryFavoriteField),
      CandySpacing.section,
      scrollable: _filterScrollable,
    );
  }

  Future<void> tapResetFilters() async {
    await tester.tap(find.byKey(WidgetKeys.discoveryResetFilters));
    await tester.pumpAndSettle();
  }

  Future<void> applyAdvancedFilters() async {
    await tester.tap(find.byKey(WidgetKeys.discoveryFilterButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(WidgetKeys.discoverySearchField),
      'Candy',
    );
    await _selectDropdownValue(WidgetKeys.discoverySortField, 'Recently added');
    await _selectDropdownValue(WidgetKeys.discoveryAddedWithinField, '30 days');
    for (final key in <Key>[
      WidgetKeys.discoveryGenre('mystery'),
      WidgetKeys.discoveryDecade(2020),
      WidgetKeys.discoveryOfficialRating('PG-13'),
      WidgetKeys.discoverySeriesStatus('continuing'),
    ]) {
      await tester.scrollUntilVisible(
        find.byKey(key),
        CandySpacing.section,
        scrollable: _filterScrollable,
      );
      await tester.tap(find.byKey(key));
      await tester.pump();
    }
    await tester.scrollUntilVisible(
      find.byKey(WidgetKeys.discoveryApplyFilters),
      CandySpacing.section,
      scrollable: _filterScrollable,
    );
    await tester.tap(find.byKey(WidgetKeys.discoveryApplyFilters));
    await tester.pumpAndSettle();
  }

  Future<void> _selectDropdownValue(Key key, String label) async {
    final field = find.byKey(key);
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  void expectSwipeVisible() {
    expect(find.byKey(WidgetKeys.discoverySwipeDeck), findsOneWidget);
  }

  void expectShuffleVisible() {
    expect(find.byKey(WidgetKeys.discoveryShuffle), findsOneWidget);
  }

  Future<void> openSwipe() async {
    await tester.tap(find.byKey(WidgetKeys.discoverySwipeMode));
    await tester.pump();
  }

  Future<void> openShuffle() async {
    await tester.tap(find.byKey(WidgetKeys.discoveryShuffleMode));
    await tester.pump();
  }

  Future<void> reveal() async {
    await tester.tap(find.byKey(WidgetKeys.discoveryRevealButton));
    await tester.pump();
  }

  Future<void> openFirstDetails() async {
    await tester.tap(find.byKey(WidgetKeys.discoveryCandidate('movie-1')));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> toggleFirstFavorite() async {
    final favorite = find.byKey(WidgetKeys.discoveryFavorite('movie-1'));
    await tester.ensureVisible(favorite);
    await tester.tap(favorite);
    await tester.pump();
  }

  Future<void> filterToMovies() async {
    await tester.tap(find.byKey(WidgetKeys.discoveryFilterButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final movieFilter = find.byKey(WidgetKeys.discoveryMovieFilter);
    await tester.ensureVisible(movieFilter);
    await tester.tap(movieFilter);
    final applyFilters = find.byKey(WidgetKeys.discoveryApplyFilters);
    await tester.scrollUntilVisible(
      applyFilters,
      300,
      scrollable: find
          .descendant(
            of: find.byKey(WidgetKeys.discoveryFilterSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(applyFilters);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> savePreset(String name) async {
    await tester.tap(find.byKey(WidgetKeys.discoveryFilterButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final nameField = find.byKey(WidgetKeys.discoveryPresetName);
    final saveButton = find.byKey(WidgetKeys.discoverySavePreset);
    await tester.scrollUntilVisible(
      nameField,
      300,
      scrollable: find
          .descendant(
            of: find.byKey(WidgetKeys.discoveryFilterSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.enterText(nameField, name);
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();
  }

  Future<void> openFiltersAtSelects() async {
    await tester.tap(find.byKey(WidgetKeys.discoveryFilterButton));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(WidgetKeys.discoveryFavoriteField),
      CandySpacing.section,
      scrollable: _filterScrollable,
    );
  }

  void expectCandidateVisible(String name) {
    expect(find.text(name), findsWidgets);
  }

  void expectDetailsVisible() {
    expect(find.byKey(WidgetKeys.discoveryDetails), findsOneWidget);
    expect(find.text('A warm mystery in space.'), findsOneWidget);
    expect(find.textContaining('2024'), findsWidgets);
    expect(find.textContaining('112'), findsWidgets);
    expect(find.textContaining('8.4'), findsWidgets);
    expect(find.textContaining('91'), findsWidgets);
    expect(find.textContaining('PG-13'), findsWidgets);
    expect(find.textContaining('Returning Series'), findsWidgets);
    expect(find.textContaining('Ava Actor'), findsWidgets);
  }

  void expectDetailsSheetNotFullHeight() {
    final viewportHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    expect(
      tester.getSize(find.byType(BottomSheet)).height,
      lessThan(viewportHeight - CandySpacing.page),
    );
  }

  void expectNoLayoutException() {
    expect(tester.takeException(), isNull);
  }

  void expectModeTransitionDuration(Duration duration) {
    final switcher = tester.widget<AnimatedSwitcher>(
      find.byKey(WidgetKeys.discoveryModeTransition),
    );
    expect(switcher.duration, duration);
  }

  void expectRevealTransitionDuration(Duration duration) {
    final switchers = tester.widgetList<AnimatedSwitcher>(
      find.descendant(
        of: find.byKey(WidgetKeys.discoveryShuffle),
        matching: find.byType(AnimatedSwitcher),
      ),
    );
    expect(switchers, hasLength(1));
    expect(switchers.single.duration, duration);
  }

  void expectCandidateUsesPressBounce(String id) {
    expect(
      tester.widget(find.byKey(WidgetKeys.discoveryCandidate(id))),
      isA<CandyBounce>(),
    );
  }

  void expectThemedHeaderVisible() {
    expect(
      find.ancestor(
        of: find.byKey(WidgetKeys.discoveryFilterButton),
        matching: find.byType(Card),
      ),
      findsOneWidget,
    );
  }

  void expectCinemaMarquee({required int candidateCount}) {
    expect(find.text('Jellyfin Picker'), findsOneWidget);
    expect(find.text('Movie night starts here'), findsOneWidget);
    expect(
      find.text('$candidateCount title ready to explore.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.theaters_rounded), findsOneWidget);
  }

  void expectFilterSelectSpacing(double minimumGap) {
    final watched = find.byKey(WidgetKeys.discoveryWatchedField);
    final favorite = find.byKey(WidgetKeys.discoveryFavoriteField);
    final gap =
        tester.getTopLeft(favorite).dy - tester.getBottomLeft(watched).dy;

    expect(gap, greaterThanOrEqualTo(minimumGap));
  }

  void expectProgressivePoster(String id) {
    final card = find.byKey(WidgetKeys.discoveryCandidate(id));
    final images = tester
        .widgetList<Image>(
          find.descendant(of: card, matching: find.byType(Image)),
        )
        .toList(growable: false);
    final providers = images
        .map((image) => image.image)
        .toList(growable: false);
    final urls = images
        .map((image) => _networkImageFor(image.image))
        .map((provider) => Uri.parse(provider.url))
        .toList(growable: false);

    expect(urls, hasLength(2));
    expect(
      providers.whereType<ResizeImage>().map((provider) => provider.width),
      containsAll(<int>[48, 600]),
    );
    expect(
      urls.map((uri) => uri.queryParameters['maxWidth']),
      containsAll(<String>['48', '600']),
    );
    expect(
      urls
          .singleWhere((uri) => uri.queryParameters['maxWidth'] == '48')
          .queryParameters['blur'],
      '20',
    );
    expect(images.any((image) => image.frameBuilder != null), isTrue);
  }

  void expectGridPosterFit(String id, BoxFit fit) {
    _expectPosterFitIn(WidgetKeys.discoveryGrid, id, fit);
  }

  void expectSwipePosterFit(String id, BoxFit fit) {
    _expectPosterFitIn(WidgetKeys.discoverySwipeDeck, id, fit);
  }

  void expectShufflePosterFit(String id, BoxFit fit) {
    _expectPosterFitIn(WidgetKeys.discoveryShuffle, id, fit);
  }

  void _expectPosterFitIn(Key modeKey, String id, BoxFit fit) {
    final mode = find.byKey(modeKey);
    final card = find.descendant(
      of: mode,
      matching: find.byKey(WidgetKeys.discoveryCandidate(id)),
    );
    final images = tester.widgetList<Image>(
      find.descendant(of: card, matching: find.byType(Image)),
    );

    expect(images, isNotEmpty);
    expect(images.map((image) => image.fit), everyElement(fit));
  }

  Finder get _filterScrollable => find.byType(Scrollable).last;

  NetworkImage _networkImageFor(ImageProvider provider) => switch (provider) {
    ResizeImage(:final imageProvider) => imageProvider as NetworkImage,
    NetworkImage() => provider,
    _ => throw TestFailure('Expected a network-backed image provider.'),
  };
}
