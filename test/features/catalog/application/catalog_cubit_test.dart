import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/features/catalog/application/catalog_cubit.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_page.dart';
import 'package:jellyfin_picker/features/catalog/domain/failures/catalog_failure.dart';
import '../../../shared/fake_catalog_repository.dart';

void main() {
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

    repository.controllers[1].add(_page('new'));
    await repository.controllers[1].close();
    await secondLoad;
    repository.controllers[0].add(_page('old'));
    await repository.controllers[0].close();
    await firstLoad;

    final state = cubit.state as CatalogLoaded;
    expect(state.candidates.single.id, 'new');
    await cubit.close();
  });

  test('should retain emitted candidates when a later page fails', () async {
    final cubit = CatalogCubit(
      SequenceCatalogRepository(<CatalogPage>[
        _page('first'),
        const CatalogPage(
          candidates: <CatalogCandidate>[],
          hasMore: false,
          nextIndex: 50,
          total: 100,
          failure: ServerCatalogFailure(),
        ),
      ]),
    );

    await cubit.load();

    final state = cubit.state as CatalogLoaded;
    expect(state.candidates.single.id, 'first');
    expect(state.failure, isA<ServerCatalogFailure>());
    await cubit.close();
  });

  test('should deduplicate candidates accumulated across pages', () async {
    final cubit = CatalogCubit(
      SequenceCatalogRepository(<CatalogPage>[_page('same'), _page('same')]),
    );

    await cubit.load();

    final state = cubit.state as CatalogLoaded;
    expect(state.candidates, hasLength(1));
    await cubit.close();
  });

  test(
    'should expose the first page before aggregating a 2,000-item library',
    () async {
      final repository = ControlledCatalogRepository();
      final cubit = CatalogCubit(repository);
      var loadCompleted = false;
      final loadFuture = cubit.load().then((_) => loadCompleted = true);
      await Future<void>.delayed(Duration.zero);

      final firstPage = _pageOf(0, hasMore: true);
      final firstState = cubit.stream
          .where((state) => state is CatalogLoaded)
          .cast<CatalogLoaded>()
          .first;
      repository.controllers.single.add(firstPage);

      expect((await firstState).candidates, hasLength(50));
      expect(loadCompleted, isFalse);

      for (var page = 1; page < 40; page++) {
        repository.controllers.single.add(
          _pageOf(page * 50, hasMore: page < 39),
        );
      }
      await repository.controllers.single.close();
      await loadFuture;

      final state = cubit.state as CatalogLoaded;
      expect(state.candidates, hasLength(2000));
      expect(
        state.candidates.map((candidate) => candidate.id).toSet(),
        hasLength(2000),
      );
      await cubit.close();
    },
  );
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
