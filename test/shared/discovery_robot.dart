import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';

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
}
