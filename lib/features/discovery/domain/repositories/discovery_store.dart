import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_snapshot.dart';

abstract interface class DiscoveryStore {
  Future<DiscoverySnapshot?> read(String scope);

  Future<void> write(String scope, DiscoverySnapshot snapshot);

  Future<void> clear(String scope);
}

abstract interface class DiscoverySelector {
  String? select(List<String> candidateIds);
}
