import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_mode.dart';

final class DiscoveryState {
  DiscoveryState({
    Iterable<CatalogCandidate> candidates = const <CatalogCandidate>[],
    this.filter = const CatalogFilter(),
    Map<String, CatalogFilter> presets = const <String, CatalogFilter>{},
    Iterable<String> likedIds = const <String>[],
    Iterable<String> rejectedIds = const <String>[],
    Iterable<String> recentPickIds = const <String>[],
    this.mode = DiscoveryMode.grid,
    this.position = 0,
    this.currentRevealId,
    this.currentPickId,
    this.isHydrated = false,
    this.persistenceError = false,
    this.noEligibleCandidates = false,
  }) : candidates = List<CatalogCandidate>.unmodifiable(candidates),
       presets = Map<String, CatalogFilter>.unmodifiable(presets),
       rejectedIds = Set<String>.unmodifiable(rejectedIds),
       likedIds = Set<String>.unmodifiable(
         likedIds.toSet()..removeAll(rejectedIds),
       ),
       recentPickIds = List<String>.unmodifiable(recentPickIds);

  final List<CatalogCandidate> candidates;
  final CatalogFilter filter;
  final Map<String, CatalogFilter> presets;
  final Set<String> likedIds;
  final Set<String> rejectedIds;
  final List<String> recentPickIds;
  final DiscoveryMode mode;
  final int position;
  final String? currentRevealId;
  final String? currentPickId;
  final bool isHydrated;
  final bool persistenceError;
  final bool noEligibleCandidates;

  List<CatalogCandidate> get filteredCandidates =>
      candidates.where(filter.matches).toList(growable: false);

  List<CatalogCandidate> get undecidedCandidates => filteredCandidates
      .where(
        (candidate) =>
            !likedIds.contains(candidate.id) &&
            !rejectedIds.contains(candidate.id),
      )
      .toList(growable: false);

  List<CatalogCandidate> get eligibleCandidates {
    final filtered = filteredCandidates;
    if (likedIds.isNotEmpty) {
      return filtered
          .where((candidate) => likedIds.contains(candidate.id))
          .toList(growable: false);
    }
    return filtered
        .where((candidate) => !rejectedIds.contains(candidate.id))
        .toList(growable: false);
  }

  DiscoveryState copyWith({
    Iterable<CatalogCandidate>? candidates,
    CatalogFilter? filter,
    Map<String, CatalogFilter>? presets,
    Iterable<String>? likedIds,
    Iterable<String>? rejectedIds,
    Iterable<String>? recentPickIds,
    DiscoveryMode? mode,
    int? position,
    Object? currentRevealId = _unset,
    Object? currentPickId = _unset,
    bool? isHydrated,
    bool? persistenceError,
    bool? noEligibleCandidates,
  }) => DiscoveryState(
    candidates: candidates ?? this.candidates,
    filter: filter ?? this.filter,
    presets: presets ?? this.presets,
    likedIds: likedIds ?? this.likedIds,
    rejectedIds: rejectedIds ?? this.rejectedIds,
    recentPickIds: recentPickIds ?? this.recentPickIds,
    mode: mode ?? this.mode,
    position: position ?? this.position,
    currentRevealId: identical(currentRevealId, _unset)
        ? this.currentRevealId
        : currentRevealId as String?,
    currentPickId: identical(currentPickId, _unset)
        ? this.currentPickId
        : currentPickId as String?,
    isHydrated: isHydrated ?? this.isHydrated,
    persistenceError: persistenceError ?? this.persistenceError,
    noEligibleCandidates: noEligibleCandidates ?? this.noEligibleCandidates,
  );
}

const _unset = Object();
