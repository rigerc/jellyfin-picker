import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/features/discovery/application/random_discovery_selector.dart';

void main() {
  test('should produce a stable deterministic sequence for the same seed', () {
    final first = RandomDiscoverySelector(random: Random(7));
    final second = RandomDiscoverySelector(random: Random(7));
    final ids = <String>['a', 'b', 'c'];

    final firstSequence = List<String?>.generate(12, (_) => first.select(ids));
    final secondSequence = List<String?>.generate(
      12,
      (_) => second.select(ids),
    );

    expect(firstSequence, secondSequence);
  });

  test('should return null for empty and select an available single ID', () {
    final selector = RandomDiscoverySelector(random: Random(1));

    expect(selector.select(<String>[]), isNull);
    expect(selector.select(<String>['only']), 'only');
  });
}
