import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_mode.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_snapshot.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_state.dart';
import 'package:jellyfin_picker/features/discovery/domain/repositories/discovery_store.dart';

final class DiscoveryCubit extends Cubit<DiscoveryState> {
  DiscoveryCubit({
    required this.store,
    required this.scopeKey,
    required this.selector,
  }) : super(DiscoveryState());

  final DiscoveryStore store;
  final String scopeKey;
  final DiscoverySelector selector;
  int _generation = 0;
  Future<void> _writeQueue = Future<void>.value();

  Future<void> hydrate() async {
    final generation = ++_generation;
    DiscoverySnapshot? snapshot;
    var failed = false;
    await _writeQueue;
    try {
      snapshot = await store.read(scopeKey);
    } on Object catch (_) {
      failed = true;
    }
    if (isClosed || generation != _generation) {
      return;
    }
    final restored = snapshot;
    if (restored == null) {
      emit(state.copyWith(isHydrated: true, persistenceError: failed));
      return;
    }
    emit(
      state.copyWith(
        filter: restored.filter,
        presets: restored.presets,
        likedIds: restored.likedIds,
        rejectedIds: restored.rejectedIds,
        recentPickIds: restored.recentPickIds,
        mode: restored.mode,
        position: restored.position,
        currentRevealId: restored.currentRevealId,
        currentPickId: restored.currentPickId,
        isHydrated: true,
        persistenceError: failed,
      ),
    );
  }

  Future<void> replaceCandidates(Iterable<CatalogCandidate> candidates) =>
      _commit(_withCandidates(List<CatalogCandidate>.of(candidates)));

  Future<void> appendCandidates(Iterable<CatalogCandidate> candidates) =>
      _commit(
        _withCandidates(<CatalogCandidate>[...state.candidates, ...candidates]),
      );

  Future<void> updateCandidate(CatalogCandidate candidate) {
    final index = state.candidates.indexWhere(
      (current) => current.id == candidate.id,
    );
    final favorite = candidate.favorite;
    if (index < 0 ||
        favorite == null ||
        state.candidates[index].favorite == favorite) {
      return Future<void>.value();
    }
    final candidates = List<CatalogCandidate>.of(state.candidates);
    candidates[index] = candidates[index].copyWith(favorite: favorite);
    return _commit(_withCandidates(candidates));
  }

  Future<void> updateFilter(CatalogFilter filter) =>
      _commit(_withFilter(filter));

  Future<void> setMode(DiscoveryMode mode) =>
      _commit(state.copyWith(mode: mode));

  Future<void> like(String id) {
    if (!_isUndecided(id)) {
      return Future<void>.value();
    }
    return _commit(
      state.copyWith(
        likedIds: <String>{...state.likedIds, id},
        position: _nextPosition,
      ),
    );
  }

  Future<void> reject(String id) {
    if (!_isUndecided(id)) {
      return Future<void>.value();
    }
    final clearReveal = state.currentRevealId == id;
    return _commit(
      state.copyWith(
        rejectedIds: <String>{...state.rejectedIds, id},
        position: _nextPosition,
        currentRevealId: clearReveal ? null : state.currentRevealId,
        currentPickId: clearReveal ? null : state.currentPickId,
      ),
    );
  }

  Future<void> dismiss(String id) => reject(id);

  Future<void> revealNext() {
    final eligible = state.eligibleCandidates;
    if (eligible.isEmpty) {
      return _commit(
        state.copyWith(
          currentRevealId: null,
          currentPickId: null,
          noEligibleCandidates: true,
        ),
      );
    }
    final alternatives = eligible
        .where((candidate) => !state.recentPickIds.contains(candidate.id))
        .toList(growable: false);
    final pool = alternatives.isEmpty ? eligible : alternatives;
    final selectedId = selector.select(
      pool.map((candidate) => candidate.id).toList(growable: false),
    );
    if (selectedId == null ||
        !pool.any((candidate) => candidate.id == selectedId)) {
      return Future<void>.value();
    }
    final recent = <String>[...state.recentPickIds, selectedId];
    return _commit(
      state.copyWith(
        recentPickIds: recent.length > 50
            ? recent.sublist(recent.length - 50)
            : recent,
        currentRevealId: selectedId,
        currentPickId: selectedId,
        noEligibleCandidates: false,
      ),
    );
  }

  Future<void> savePreset(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty || normalized.length > 50) {
      throw ArgumentError.value(name, 'name', 'must be 1–50 characters');
    }
    final presets = <String, CatalogFilter>{
      ...state.presets,
      normalized: state.filter,
    };
    final boundedPresets = presets.length > 20
        ? Map<String, CatalogFilter>.fromEntries(
            presets.entries.skip(presets.length - 20),
          )
        : presets;
    return _commit(state.copyWith(presets: boundedPresets));
  }

  Future<void> applyPreset(String name) {
    final filter = state.presets[name.trim()];
    return filter == null ? Future<void>.value() : updateFilter(filter);
  }

  Future<void> clearDiscovery() async {
    final generation = ++_generation;
    emit(
      state.copyWith(
        filter: const CatalogFilter(),
        presets: const <String, CatalogFilter>{},
        likedIds: const <String>{},
        rejectedIds: const <String>{},
        recentPickIds: const <String>[],
        position: 0,
        currentRevealId: null,
        currentPickId: null,
        persistenceError: false,
        noEligibleCandidates: false,
      ),
    );
    await _enqueue(() async {
      try {
        await store.clear(scopeKey);
      } on Object catch (_) {
        if (!isClosed && generation == _generation) {
          emit(state.copyWith(persistenceError: true));
        }
      }
    });
  }

  Future<void> _commit(DiscoveryState next) async {
    if (isClosed) {
      return;
    }
    final generation = ++_generation;
    emit(next);
    await _enqueue(() async {
      try {
        await store.write(scopeKey, _snapshotFromState(next));
      } on Object catch (_) {
        if (!isClosed && generation == _generation) {
          emit(state.copyWith(persistenceError: true));
        }
      }
    });
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _writeQueue.then((_) => operation());
    _writeQueue = next.then<void>((_) {}, onError: (_) {});
    return next;
  }

  DiscoveryState _withCandidates(List<CatalogCandidate> candidates) {
    final unique = <String, CatalogCandidate>{};
    for (final candidate in candidates) {
      unique.putIfAbsent(candidate.id, () => candidate);
    }
    final values = unique.values.toList(growable: false);
    final reveal = _validReveal(values, state.filter, state.currentRevealId);
    return state.copyWith(
      candidates: values,
      currentRevealId: reveal,
      currentPickId: reveal == null ? null : state.currentPickId,
      noEligibleCandidates: false,
    );
  }

  DiscoveryState _withFilter(CatalogFilter filter) {
    final reveal = _validReveal(
      state.candidates,
      filter,
      state.currentRevealId,
    );
    return state.copyWith(
      filter: filter,
      currentRevealId: reveal,
      currentPickId: reveal == null ? null : state.currentPickId,
      noEligibleCandidates: false,
    );
  }

  bool _isUndecided(String id) =>
      state.undecidedCandidates.any((candidate) => candidate.id == id);

  int get _nextPosition => state.position + 1;

  String? _validReveal(
    List<CatalogCandidate> candidates,
    CatalogFilter filter,
    String? reveal,
  ) {
    if (reveal == null) {
      return null;
    }
    final candidate = candidates.where((item) => item.id == reveal).firstOrNull;
    if (candidate == null || !filter.matches(candidate)) {
      return null;
    }
    if (state.rejectedIds.contains(reveal)) {
      return null;
    }
    if (state.likedIds.isNotEmpty && !state.likedIds.contains(reveal)) {
      return null;
    }
    return reveal;
  }

  DiscoverySnapshot _snapshotFromState(DiscoveryState value) =>
      DiscoverySnapshot(
        filter: value.filter,
        presets: value.presets,
        likedIds: value.likedIds,
        rejectedIds: value.rejectedIds,
        recentPickIds: value.recentPickIds,
        mode: value.mode,
        position: value.position,
        currentRevealId: value.currentRevealId,
        currentPickId: value.currentPickId,
      );
}
