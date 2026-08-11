import 'dart:math';

import 'package:jellyfin_picker/features/discovery/domain/repositories/discovery_store.dart';

final class RandomDiscoverySelector implements DiscoverySelector {
  RandomDiscoverySelector({Random? random}) : _random = random ?? Random();

  final Random _random;

  @override
  String? select(List<String> candidateIds) {
    if (candidateIds.isEmpty) {
      return null;
    }
    return candidateIds[_random.nextInt(candidateIds.length)];
  }
}
