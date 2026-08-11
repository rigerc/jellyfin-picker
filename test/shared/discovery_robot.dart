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
    await tester.tap(find.byKey(WidgetKeys.discoveryFavorite('movie-1')));
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
      find.text('Favorite state'),
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

  void expectNoLayoutException() {
    expect(tester.takeException(), isNull);
  }

  void expectModeTransitionDuration(Duration duration) {
    final switcher = tester.widget<AnimatedSwitcher>(
      find
          .descendant(
            of: find.byKey(WidgetKeys.discoveryPage),
            matching: find.byType(AnimatedSwitcher),
          )
          .first,
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
    final watched = _inputDecoratorFor('Watched state');
    final favorite = _inputDecoratorFor('Favorite state');
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

  Finder get _filterScrollable => find
      .descendant(
        of: find.byKey(WidgetKeys.discoveryFilterSheet),
        matching: find.byType(Scrollable),
      )
      .first;

  Finder _inputDecoratorFor(String label) => find
      .ancestor(of: find.text(label), matching: find.byType(InputDecorator))
      .first;

  NetworkImage _networkImageFor(ImageProvider provider) => switch (provider) {
    ResizeImage(:final imageProvider) => imageProvider as NetworkImage,
    NetworkImage() => provider,
    _ => throw TestFailure('Expected a network-backed image provider.'),
  };
}
