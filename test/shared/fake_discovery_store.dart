import 'dart:async';

import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_snapshot.dart';
import 'package:jellyfin_picker/features/discovery/domain/repositories/discovery_store.dart';

final class FakeDiscoveryStore implements DiscoveryStore {
  DiscoverySnapshot? snapshot;
  String? lastScope;
  int clearCount = 0;
  Duration readDelay = Duration.zero;
  Duration writeDelay = Duration.zero;
  Duration clearDelay = Duration.zero;

  @override
  Future<DiscoverySnapshot?> read(String scope) async {
    lastScope = scope;
    await Future<void>.delayed(readDelay);
    return snapshot;
  }

  @override
  Future<void> write(String scope, DiscoverySnapshot value) async {
    lastScope = scope;
    await Future<void>.delayed(writeDelay);
    snapshot = value;
  }

  @override
  Future<void> clear(String scope) async {
    lastScope = scope;
    await Future<void>.delayed(clearDelay);
    clearCount++;
    snapshot = null;
  }
}

final class ControlledDiscoveryStore implements DiscoveryStore {
  final readCompleter = Completer<DiscoverySnapshot?>();
  final clearCompleter = Completer<void>();
  DiscoverySnapshot? snapshot;

  @override
  Future<DiscoverySnapshot?> read(String scope) => readCompleter.future;

  @override
  Future<void> write(String scope, DiscoverySnapshot value) {
    snapshot = value;
    return Future<void>.value();
  }

  @override
  Future<void> clear(String scope) => clearCompleter.future;
}

final class FakeDiscoverySelector implements DiscoverySelector {
  FakeDiscoverySelector(this.selectedId);

  final String? selectedId;
  List<String?> choices = <String?>[];
  List<String> receivedIds = <String>[];
  List<List<String>> receivedCalls = <List<String>>[];

  @override
  String? select(List<String> candidateIds) {
    receivedIds = List<String>.of(candidateIds);
    receivedCalls.add(List<String>.of(candidateIds));
    return choices.isEmpty ? selectedId : choices.removeAt(0);
  }
}
