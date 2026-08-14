import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/features/catalog/application/catalog_cubit.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_facets.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_library.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_page.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_result.dart';
import 'package:jellyfin_picker/features/catalog/domain/failures/catalog_failure.dart';
import '../../../shared/fake_catalog_repository.dart';

void main() {
  test('should stop after one bounded page until more is requested', () async {
    final repository = PagingCatalogRepository(
      pages: <int, CatalogPage>{
        0: _pageOf(0, hasMore: true),
        50: _pageOf(50, hasMore: false),
      },
    );
    final cubit = CatalogCubit(repository);

    await cubit.load();

    final state = cubit.state as CatalogLoaded;
    expect(state.candidates, hasLength(50));
    expect(state.hasMore, isTrue);
    expect(state.loadingMore, isFalse);
    expect(repository.startIndexes, <int>[0]);
    await cubit.close();
  });

  test('should append the next bounded page when more is requested', () async {
    final repository = PagingCatalogRepository(
      pages: <int, CatalogPage>{
        0: _pageOf(0, hasMore: true),
        50: _pageOf(50, hasMore: false),
      },
    );
    final cubit = CatalogCubit(repository);

    await cubit.load();
    await cubit.loadMore();

    final state = cubit.state as CatalogLoaded;
    expect(state.candidates, hasLength(100));
    expect(state.hasMore, isFalse);
    expect(repository.startIndexes, <int>[0, 50]);
    await cubit.close();
  });

  test(
    'should expose Jellyfin libraries and facets with the first page',
    () async {
      const libraries = <CatalogLibrary>[
        CatalogLibrary(
          id: 'movies-id',
          name: 'Movies',
          collectionType: 'movies',
        ),
      ];
      const facets = CatalogFacets(
        genres: <String>['Drama'],
        years: <int>[2024],
        officialRatings: <String>['PG-13'],
      );
      final repository = PagingCatalogRepository(
        pages: <int, CatalogPage>{0: _page('movie-1')},
        libraries: libraries,
        facets: facets,
      );
      final cubit = CatalogCubit(repository);

      await cubit.load();

      final state = cubit.state as CatalogLoaded;
      expect(state.libraries, libraries);
      expect(state.facets, facets);
      await cubit.close();
    },
  );

  test(
    'should expose the first page before supporting metadata returns',
    () async {
      final repository = _DelayedMetadataCatalogRepository(_page('movie-1'));
      final cubit = CatalogCubit(repository);

      final loading = cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<CatalogLoaded>());
      expect((cubit.state as CatalogLoaded).candidates.single.id, 'movie-1');

      repository.libraries.complete(
        const CatalogResult<List<CatalogLibrary>>.success(<CatalogLibrary>[]),
      );
      repository.facets.complete(
        const CatalogResult<CatalogFacets>.success(CatalogFacets()),
      );
      await loading;
      await cubit.close();
    },
  );

  test('should cache lazily loaded item details by id', () async {
    final details = CatalogCandidate(
      id: 'movie-1',
      name: 'Detailed movie',
      mediaType: CatalogMediaType.movie,
      overview: 'Full synopsis',
      poster: const CatalogImage.fallback(),
      backdrop: const CatalogImage.fallback(),
    );
    final repository = PagingCatalogRepository(
      pages: <int, CatalogPage>{0: _page('movie-1')},
      details: details,
    );
    final cubit = CatalogCubit(repository);

    final first = await cubit.loadDetails('movie-1');
    final second = await cubit.loadDetails('movie-1');

    expect(first.value, same(details));
    expect(second.value, same(details));
    expect(first.failure, isNull);
    expect(repository.detailCalls, 1);
    await cubit.close();
  });

  test('should forward excluded decisions to a replacement batch', () async {
    final repository = PagingCatalogRepository(
      pages: <int, CatalogPage>{0: _page('movie-1')},
    );
    final cubit = CatalogCubit(repository);

    await cubit.load(excludedIds: const <String>{'seen-1', 'seen-2'});

    expect(repository.excludedIdSets.single, const <String>{
      'seen-1',
      'seen-2',
    });
    await cubit.close();
  });

  test('should expose the first catalog page when loading succeeds', () async {
    final cubit = CatalogCubit(
      FakeCatalogRepository(
        const CatalogPage(
          candidates: <CatalogCandidate>[
            CatalogCandidate(
              id: 'movie-1',
              name: 'Candy Movie',
              mediaType: CatalogMediaType.movie,
              poster: CatalogImage.fallback(),
              backdrop: CatalogImage.fallback(),
            ),
          ],
          hasMore: true,
          nextIndex: 50,
          total: 100,
        ),
      ),
    );

    await cubit.load();

    expect(cubit.state, isA<CatalogLoaded>());
    expect((cubit.state as CatalogLoaded).candidates, hasLength(1));
    await cubit.close();
  });

  test('should ignore a late page from an older overlapping load', () async {
    final repository = ControlledCatalogRepository();
    final cubit = CatalogCubit(repository);
    final firstLoad = cubit.load();
    await Future<void>.delayed(Duration.zero);
    final secondLoad = cubit.load();
    await Future<void>.delayed(Duration.zero);

    repository.pageCompleters[1].complete(_page('new'));
    await secondLoad;
    repository.pageCompleters[0].complete(_page('old'));
    await firstLoad;

    final state = cubit.state as CatalogLoaded;
    expect(state.candidates.single.id, 'new');
    await cubit.close();
  });

  test('should retain emitted candidates when a later page fails', () async {
    final cubit = CatalogCubit(
      PagingCatalogRepository(
        pages: <int, CatalogPage>{
          0: CatalogPage(
            candidates: _page('first').candidates,
            hasMore: true,
            nextIndex: 1,
            total: 2,
          ),
          1: const CatalogPage(
            candidates: <CatalogCandidate>[],
            hasMore: false,
            nextIndex: 1,
            total: 2,
            failure: ServerCatalogFailure(),
          ),
        },
      ),
    );

    await cubit.load();
    await cubit.loadMore();

    final state = cubit.state as CatalogLoaded;
    expect(state.candidates.single.id, 'first');
    expect(state.failure, isA<ServerCatalogFailure>());
    await cubit.close();
  });

  test('should deduplicate candidates accumulated across pages', () async {
    final first = CatalogPage(
      candidates: _page('same').candidates,
      hasMore: true,
      nextIndex: 1,
      total: 2,
    );
    final cubit = CatalogCubit(
      PagingCatalogRepository(
        pages: <int, CatalogPage>{0: first, 1: _page('same')},
      ),
    );

    await cubit.load();
    await cubit.loadMore();

    final state = cubit.state as CatalogLoaded;
    expect(state.candidates, hasLength(1));
    await cubit.close();
  });
}

CatalogPage _page(String id) => CatalogPage(
  candidates: <CatalogCandidate>[
    CatalogCandidate(
      id: id,
      name: id,
      mediaType: CatalogMediaType.movie,
      poster: const CatalogImage.fallback(),
      backdrop: const CatalogImage.fallback(),
    ),
  ],
  hasMore: false,
  nextIndex: 1,
  total: 1,
);

CatalogPage _pageOf(int start, {required bool hasMore}) => CatalogPage(
  candidates: List<CatalogCandidate>.generate(
    50,
    (offset) => CatalogCandidate(
      id: 'movie-${start + offset}',
      name: 'Movie ${start + offset}',
      mediaType: CatalogMediaType.movie,
      poster: const CatalogImage.fallback(),
      backdrop: const CatalogImage.fallback(),
    ),
  ),
  hasMore: hasMore,
  nextIndex: start + 50,
  total: 2000,
);

final class _DelayedMetadataCatalogRepository
    extends CatalogRepositoryFakeBase {
  _DelayedMetadataCatalogRepository(this.page);

  final CatalogPage page;
  final libraries = Completer<CatalogResult<List<CatalogLibrary>>>();
  final facets = Completer<CatalogResult<CatalogFacets>>();

  @override
  Future<CatalogPage> loadPage({
    CatalogFilter filter = const CatalogFilter(),
    int startIndex = 0,
    Set<String> excludedIds = const <String>{},
    Set<String> includedIds = const <String>{},
  }) async => page;

  @override
  Future<CatalogResult<List<CatalogLibrary>>> loadLibraries() =>
      libraries.future;

  @override
  Future<CatalogResult<CatalogFacets>> loadFacets({String? parentId}) =>
      facets.future;

  @override
  Stream<CatalogPage> streamPages({
    CatalogFilter filter = const CatalogFilter(),
  }) => const Stream<CatalogPage>.empty();
}
