import 'dart:async';

import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_facets.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_library.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_page.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_result.dart';
import 'package:jellyfin_picker/features/catalog/domain/failures/catalog_failure.dart';
import 'package:jellyfin_picker/features/catalog/domain/repositories/catalog_repository.dart';

abstract base class CatalogRepositoryFakeBase implements CatalogRepository {
  @override
  Future<CatalogResult<List<CatalogLibrary>>> loadLibraries() async =>
      const CatalogResult<List<CatalogLibrary>>.success(<CatalogLibrary>[]);

  @override
  Future<CatalogResult<CatalogFacets>> loadFacets({String? parentId}) async =>
      const CatalogResult<CatalogFacets>.success(CatalogFacets());

  @override
  Future<CatalogResult<CatalogCandidate>> loadDetails(String itemId) async =>
      const CatalogResult<CatalogCandidate>.failure(
        IncompatibleCatalogFailure(),
      );
}

final class FakeCatalogRepository extends CatalogRepositoryFakeBase {
  FakeCatalogRepository(
    this.page, {
    this.libraries = const <CatalogLibrary>[],
    this.facets = const CatalogFacets(),
    this.details,
  });

  final CatalogPage page;
  final List<CatalogLibrary> libraries;
  final CatalogFacets facets;
  final CatalogCandidate? details;
  final loadPageStartIndexes = <int>[];
  var detailCalls = 0;

  @override
  Future<CatalogPage> loadPage({
    CatalogFilter filter = const CatalogFilter(),
    int startIndex = 0,
    Set<String> excludedIds = const <String>{},
    Set<String> includedIds = const <String>{},
  }) async {
    loadPageStartIndexes.add(startIndex);
    return page;
  }

  @override
  Future<CatalogResult<List<CatalogLibrary>>> loadLibraries() async =>
      CatalogResult<List<CatalogLibrary>>.success(libraries);

  @override
  Future<CatalogResult<CatalogFacets>> loadFacets({String? parentId}) async =>
      CatalogResult<CatalogFacets>.success(facets);

  @override
  Future<CatalogResult<CatalogCandidate>> loadDetails(String itemId) async {
    detailCalls++;
    final value = details;
    return value == null
        ? const CatalogResult<CatalogCandidate>.failure(
            IncompatibleCatalogFailure(),
          )
        : CatalogResult<CatalogCandidate>.success(value);
  }

  @override
  Stream<CatalogPage> streamPages({
    CatalogFilter filter = const CatalogFilter(),
  }) async* {
    yield page;
  }
}

final class ControlledCatalogRepository extends CatalogRepositoryFakeBase {
  final controllers = <StreamController<CatalogPage>>[];
  final pageCompleters = <Completer<CatalogPage>>[];

  @override
  Future<CatalogPage> loadPage({
    CatalogFilter filter = const CatalogFilter(),
    int startIndex = 0,
    Set<String> excludedIds = const <String>{},
    Set<String> includedIds = const <String>{},
  }) {
    final completer = Completer<CatalogPage>();
    pageCompleters.add(completer);
    return completer.future;
  }

  @override
  Stream<CatalogPage> streamPages({
    CatalogFilter filter = const CatalogFilter(),
  }) {
    final controller = StreamController<CatalogPage>();
    controllers.add(controller);
    return controller.stream;
  }
}

final class SequenceCatalogRepository extends CatalogRepositoryFakeBase {
  SequenceCatalogRepository(this.pages);

  final List<CatalogPage> pages;

  @override
  Future<CatalogPage> loadPage({
    CatalogFilter filter = const CatalogFilter(),
    int startIndex = 0,
    Set<String> excludedIds = const <String>{},
    Set<String> includedIds = const <String>{},
  }) async => pages.first;

  @override
  Stream<CatalogPage> streamPages({
    CatalogFilter filter = const CatalogFilter(),
  }) async* {
    yield* Stream<CatalogPage>.fromIterable(pages);
  }
}

final class PagingCatalogRepository extends CatalogRepositoryFakeBase {
  PagingCatalogRepository({
    required this.pages,
    this.libraries = const <CatalogLibrary>[],
    this.facets = const CatalogFacets(),
    this.details,
  });

  final Map<int, CatalogPage> pages;
  final List<CatalogLibrary> libraries;
  final CatalogFacets facets;
  final CatalogCandidate? details;
  final startIndexes = <int>[];
  final excludedIdSets = <Set<String>>[];
  var detailCalls = 0;

  @override
  Future<CatalogPage> loadPage({
    CatalogFilter filter = const CatalogFilter(),
    int startIndex = 0,
    Set<String> excludedIds = const <String>{},
    Set<String> includedIds = const <String>{},
  }) async {
    startIndexes.add(startIndex);
    excludedIdSets.add(Set<String>.of(excludedIds));
    return pages[startIndex] ??
        const CatalogPage(
          candidates: <CatalogCandidate>[],
          hasMore: false,
          nextIndex: 0,
          total: 0,
        );
  }

  @override
  Future<CatalogResult<List<CatalogLibrary>>> loadLibraries() async =>
      CatalogResult<List<CatalogLibrary>>.success(libraries);

  @override
  Future<CatalogResult<CatalogFacets>> loadFacets({String? parentId}) async =>
      CatalogResult<CatalogFacets>.success(facets);

  @override
  Future<CatalogResult<CatalogCandidate>> loadDetails(String itemId) async {
    detailCalls++;
    final value = details;
    return value == null
        ? const CatalogResult<CatalogCandidate>.failure(
            IncompatibleCatalogFailure(),
          )
        : CatalogResult<CatalogCandidate>.success(value);
  }

  @override
  Stream<CatalogPage> streamPages({
    CatalogFilter filter = const CatalogFilter(),
  }) async* {
    for (final page in pages.values) {
      yield page;
    }
  }
}
