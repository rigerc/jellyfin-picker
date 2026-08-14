import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_facets.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_library.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_result.dart';
import 'package:jellyfin_picker/features/catalog/domain/failures/catalog_failure.dart';
import 'package:jellyfin_picker/features/catalog/domain/repositories/catalog_repository.dart';

sealed class CatalogState {
  const CatalogState();
}

final class CatalogIdle extends CatalogState {
  const CatalogIdle();
}

final class CatalogLoading extends CatalogState {
  const CatalogLoading();
}

final class CatalogLoaded extends CatalogState {
  const CatalogLoaded({
    required this.candidates,
    required this.hasMore,
    required this.nextIndex,
    required this.total,
    this.libraries = const <CatalogLibrary>[],
    this.facets = const CatalogFacets(),
    this.failure,
    this.loadingMore = false,
  });

  final List<CatalogCandidate> candidates;
  final bool hasMore;
  final int nextIndex;
  final int total;
  final List<CatalogLibrary> libraries;
  final CatalogFacets facets;
  final CatalogFailure? failure;
  final bool loadingMore;

  CatalogLoaded copyWith({
    List<CatalogCandidate>? candidates,
    bool? hasMore,
    int? nextIndex,
    int? total,
    List<CatalogLibrary>? libraries,
    CatalogFacets? facets,
    Object? failure = _unset,
    bool? loadingMore,
  }) => CatalogLoaded(
    candidates: candidates ?? this.candidates,
    hasMore: hasMore ?? this.hasMore,
    nextIndex: nextIndex ?? this.nextIndex,
    total: total ?? this.total,
    libraries: libraries ?? this.libraries,
    facets: facets ?? this.facets,
    failure: identical(failure, _unset)
        ? this.failure
        : failure as CatalogFailure?,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

final class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this.repository) : super(const CatalogIdle());

  final CatalogRepository repository;
  int _generation = 0;
  CatalogFilter _filter = const CatalogFilter();
  Set<String> _excludedIds = const <String>{};
  Set<String> _includedIds = const <String>{};
  List<CatalogLibrary>? _libraries;
  final _facetCache = <String?, CatalogFacets>{};
  final _detailCache = <String, CatalogResult<CatalogCandidate>>{};

  Future<void> load({
    CatalogFilter filter = const CatalogFilter(),
    Set<String> excludedIds = const <String>{},
    Set<String> includedIds = const <String>{},
  }) async {
    final generation = ++_generation;
    if (isClosed) {
      return;
    }
    emit(const CatalogLoading());
    _filter = filter;
    _excludedIds = Set<String>.unmodifiable(excludedIds);
    _includedIds = Set<String>.unmodifiable(includedIds);
    final librariesRequest = _libraries == null
        ? repository.loadLibraries()
        : Future<CatalogResult<List<CatalogLibrary>>>.value(
            CatalogResult<List<CatalogLibrary>>.success(_libraries),
          );
    final parentId = filter.libraryId;
    final cachedFacets = _facetCache[parentId];
    final facetsRequest = cachedFacets == null
        ? repository.loadFacets(parentId: parentId)
        : Future<CatalogResult<CatalogFacets>>.value(
            CatalogResult<CatalogFacets>.success(cachedFacets),
          );
    final pageRequest = repository.loadPage(
      filter: filter,
      excludedIds: _excludedIds,
      includedIds: _includedIds,
    );
    final page = await pageRequest;
    if (isClosed || generation != _generation) {
      return;
    }
    emit(
      CatalogLoaded(
        candidates: List<CatalogCandidate>.unmodifiable(page.candidates),
        hasMore: page.hasMore,
        nextIndex: page.nextIndex,
        total: page.total,
        libraries: _libraries ?? const <CatalogLibrary>[],
        facets: cachedFacets ?? const CatalogFacets(),
        failure: page.failure,
      ),
    );
    final librariesResult = await librariesRequest;
    final facetsResult = await facetsRequest;
    if (isClosed || generation != _generation) {
      return;
    }
    if (librariesResult.value case final libraries?) {
      _libraries = libraries;
    }
    if (facetsResult.value case final facets?) {
      _facetCache[parentId] = facets;
    }
    final current = state;
    if (current is CatalogLoaded) {
      emit(
        current.copyWith(
          libraries: _libraries ?? const <CatalogLibrary>[],
          facets: _facetCache[parentId] ?? const CatalogFacets(),
          failure:
              current.failure ??
              librariesResult.failure ??
              facetsResult.failure,
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! CatalogLoaded ||
        !current.hasMore ||
        current.loadingMore ||
        isClosed) {
      return;
    }
    final generation = _generation;
    emit(current.copyWith(loadingMore: true));
    final page = await repository.loadPage(
      filter: _filter,
      startIndex: current.nextIndex,
      excludedIds: _excludedIds,
      includedIds: _includedIds,
    );
    if (isClosed || generation != _generation) {
      return;
    }
    final candidates = <String, CatalogCandidate>{
      for (final candidate in current.candidates) candidate.id: candidate,
      for (final candidate in page.candidates) candidate.id: candidate,
    }.values.toList(growable: false);
    emit(
      current.copyWith(
        candidates: List<CatalogCandidate>.unmodifiable(candidates),
        hasMore: page.hasMore,
        nextIndex: page.nextIndex,
        total: page.total,
        failure: page.failure,
        loadingMore: false,
      ),
    );
  }

  Future<CatalogResult<CatalogCandidate>> loadDetails(String itemId) async {
    final normalizedId = itemId.trim();
    final cached = _detailCache[normalizedId];
    if (cached != null) {
      return cached;
    }
    final result = await repository.loadDetails(normalizedId);
    if (result.value != null) {
      _detailCache[normalizedId] = result;
    }
    return result;
  }
}

const _unset = Object();
