import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_mode.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_snapshot.dart';
import 'package:jellyfin_picker/features/discovery/domain/repositories/discovery_store.dart';
import '../../../shared/fake_discovery_store.dart';

void main() {
  test('should preserve discovery state when the mode changes', () async {
    final store = FakeDiscoveryStore();
    final cubit = DiscoveryCubit(
      store: store,
      scopeKey: 'https://server/user',
      selector: FakeDiscoverySelector('movie-1'),
    );
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate('movie-1')]);
    await cubit.like('movie-1');
    await cubit.savePreset('  Picks  ');
    await cubit.revealNext();
    await cubit.setMode(DiscoveryMode.shuffle);

    expect(cubit.state.mode, DiscoveryMode.shuffle);
    expect(cubit.state.likedIds, contains('movie-1'));
    expect(cubit.state.presets.keys, contains('Picks'));
    expect(cubit.state.currentRevealId, 'movie-1');
    await cubit.close();
  });

  test(
    'should consume binary decisions and keep rejected titles ineligible',
    () async {
      final cubit = _cubit(FakeDiscoverySelector('movie-1'));
      await cubit.replaceCandidates(<CatalogCandidate>[
        _candidate('movie-1'),
        _candidate('movie-2'),
      ]);

      await cubit.reject('movie-1');
      await cubit.like('movie-2');

      expect(cubit.state.undecidedCandidates, isEmpty);
      expect(cubit.state.eligibleCandidates.map((item) => item.id), <String>[
        'movie-2',
      ]);
      expect(cubit.state.rejectedIds, contains('movie-1'));
      await cubit.close();
    },
  );

  test('should use remaining undecided titles when no likes exist', () async {
    final selector = FakeDiscoverySelector('movie-2');
    final cubit = _cubit(selector);
    await cubit.replaceCandidates(<CatalogCandidate>[
      _candidate('movie-1'),
      _candidate('movie-2'),
    ]);
    await cubit.reject('movie-1');
    await cubit.revealNext();

    expect(selector.receivedIds, <String>['movie-2']);
    expect(cubit.state.currentRevealId, 'movie-2');
    await cubit.close();
  });

  test('should treat dismiss as a rejected browsing decision', () async {
    final cubit = _cubit(FakeDiscoverySelector(null));
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate('movie-1')]);
    await cubit.dismiss('movie-1');

    expect(cubit.state.rejectedIds, contains('movie-1'));
    expect(cubit.state.eligibleCandidates, isEmpty);
    await cubit.close();
  });

  test(
    'should restrict final picks to liked titles when likes exist',
    () async {
      final selector = FakeDiscoverySelector('movie-2');
      final cubit = _cubit(selector);
      await cubit.replaceCandidates(<CatalogCandidate>[
        _candidate('movie-1'),
        _candidate('movie-2'),
      ]);
      await cubit.like('movie-1');
      await cubit.revealNext();

      expect(selector.receivedIds, <String>['movie-1']);
      expect(cubit.state.currentRevealId, isNull);
      await cubit.close();
    },
  );

  test('should avoid recent picks while alternatives remain', () async {
    final selector = FakeDiscoverySelector('movie-2');
    selector.choices = <String?>['movie-1', 'movie-2'];
    final cubit = _cubit(selector);
    await cubit.replaceCandidates(<CatalogCandidate>[
      _candidate('movie-1'),
      _candidate('movie-2'),
    ]);
    await cubit.revealNext();
    await cubit.revealNext();

    expect(selector.receivedCalls, <List<String>>[
      <String>['movie-1', 'movie-2'],
      <String>['movie-2'],
    ]);
    expect(cubit.state.recentPickIds, <String>['movie-1', 'movie-2']);
    await cubit.close();
  });

  test('should clear the current reveal when it is rejected', () async {
    final selector = FakeDiscoverySelector('movie-1');
    final cubit = _cubit(selector);
    await cubit.replaceCandidates(<CatalogCandidate>[_candidate('movie-1')]);
    await cubit.revealNext();
    await cubit.reject('movie-1');

    expect(cubit.state.currentRevealId, isNull);
    expect(cubit.state.currentPickId, isNull);
    await cubit.close();
  });

  test(
    'should expose no-eligible state when reveal has no candidates',
    () async {
      final cubit = _cubit(FakeDiscoverySelector(null));
      await cubit.replaceCandidates(<CatalogCandidate>[_candidate('movie-1')]);
      await cubit.reject('movie-1');
      await cubit.revealNext();

      expect(cubit.state.noEligibleCandidates, isTrue);
      expect(cubit.state.currentRevealId, isNull);
      await cubit.close();
    },
  );

  test(
    'should clear no-eligible state when an eligible candidate is appended',
    () async {
      final cubit = _cubit(FakeDiscoverySelector(null));
      await cubit.replaceCandidates(<CatalogCandidate>[_candidate('rejected')]);
      await cubit.reject('rejected');
      await cubit.revealNext();

      await cubit.appendCandidates(<CatalogCandidate>[_candidate('eligible')]);

      expect(cubit.state.noEligibleCandidates, isFalse);
      await cubit.close();
    },
  );

  test(
    'should clear no-eligible state when discovery data is cleared',
    () async {
      final cubit = _cubit(FakeDiscoverySelector(null));
      await cubit.replaceCandidates(<CatalogCandidate>[_candidate('movie')]);
      await cubit.reject('movie');
      await cubit.revealNext();

      await cubit.clearDiscovery();

      expect(cubit.state.noEligibleCandidates, isFalse);
      await cubit.close();
    },
  );

  test(
    'should preserve decisions while refreshing candidates and filters',
    () async {
      final cubit = _cubit(FakeDiscoverySelector(null));
      await cubit.replaceCandidates(<CatalogCandidate>[
        _candidate('movie-1'),
        _candidate('movie-2'),
      ]);
      await cubit.reject('movie-1');
      await cubit.updateFilter(
        const CatalogFilter(
          mediaTypes: <CatalogMediaType>{CatalogMediaType.movie},
        ),
      );
      await cubit.replaceCandidates(<CatalogCandidate>[_candidate('movie-2')]);

      expect(cubit.state.rejectedIds, contains('movie-1'));
      expect(cubit.state.candidates, hasLength(1));
      expect(cubit.state.eligibleCandidates.single.id, 'movie-2');
      await cubit.close();
    },
  );

  test('should recompute eligibility when the active filter changes', () async {
    final cubit = _cubit(FakeDiscoverySelector(null));
    await cubit.replaceCandidates(<CatalogCandidate>[
      _candidate('movie-1'),
      _candidate('series-1', type: CatalogMediaType.series),
    ]);
    await cubit.updateFilter(
      const CatalogFilter(
        mediaTypes: <CatalogMediaType>{CatalogMediaType.series},
      ),
    );

    expect(cubit.state.eligibleCandidates.single.id, 'series-1');
    await cubit.close();
  });

  test(
    'should append progressive candidates without clearing decisions',
    () async {
      final cubit = _cubit(FakeDiscoverySelector(null));
      await cubit.replaceCandidates(<CatalogCandidate>[_candidate('movie-1')]);
      await cubit.like('movie-1');
      await cubit.appendCandidates(<CatalogCandidate>[_candidate('movie-2')]);

      expect(cubit.state.candidates, hasLength(2));
      expect(cubit.state.likedIds, contains('movie-1'));
      await cubit.close();
    },
  );

  test(
    'should propagate a favorite replacement across shared discovery modes',
    () async {
      final cubit = _cubit(FakeDiscoverySelector(null));
      await cubit.replaceCandidates(<CatalogCandidate>[
        _candidate('liked', watched: true, favorite: false),
        _candidate('rejected'),
      ]);
      await cubit.like('liked');
      await cubit.reject('rejected');
      await cubit.updateFilter(const CatalogFilter(favorite: true));

      await cubit.updateCandidate(
        _candidate('liked', watched: false, favorite: true),
      );
      await cubit.setMode(DiscoveryMode.swipe);
      await cubit.setMode(DiscoveryMode.shuffle);

      final updated = cubit.state.candidates.first;
      expect(
        (
          favorite: updated.favorite,
          watched: updated.watched,
          likedIds: (cubit.state.likedIds.toList()..sort()).join(','),
          rejectedIds: (cubit.state.rejectedIds.toList()..sort()).join(','),
          eligibleIds: cubit.state.eligibleCandidates
              .map((candidate) => candidate.id)
              .join(','),
          mode: cubit.state.mode,
        ),
        (
          favorite: true,
          watched: true,
          likedIds: 'liked',
          rejectedIds: 'rejected',
          eligibleIds: 'liked',
          mode: DiscoveryMode.shuffle,
        ),
      );
      await cubit.close();
    },
  );

  test(
    'should keep the latest same-ID favorite update when writes overlap',
    () async {
      final store = FakeDiscoveryStore()
        ..writeDelay = const Duration(milliseconds: 10);
      final cubit = DiscoveryCubit(
        store: store,
        scopeKey: 'server/user',
        selector: FakeDiscoverySelector(null),
      );
      await cubit.replaceCandidates(<CatalogCandidate>[
        _candidate('movie', watched: false, favorite: false),
      ]);

      final candidate = cubit.state.candidates.single;
      final first = cubit.updateCandidate(candidate.copyWith(favorite: true));
      final latest = cubit.updateCandidate(candidate.copyWith(favorite: false));
      final immediateFavorite = cubit.state.candidates.single.favorite;
      await Future.wait(<Future<void>>[first, latest]);

      expect(
        (
          favorite: cubit.state.candidates.single.favorite,
          immediateFavorite: immediateFavorite,
          watched: cubit.state.candidates.single.watched,
          likedIds: cubit.state.likedIds.length,
          rejectedIds: cubit.state.rejectedIds.length,
        ),
        (
          favorite: false,
          immediateFavorite: false,
          watched: false,
          likedIds: 0,
          rejectedIds: 0,
        ),
      );
      await cubit.close();
    },
  );

  test('should trim and overwrite named presets', () async {
    final cubit = _cubit(FakeDiscoverySelector(null));
    await cubit.savePreset('  Watchlist  ');
    await cubit.updateFilter(const CatalogFilter(favorite: true));
    await cubit.savePreset('Watchlist');

    expect(cubit.state.presets, hasLength(1));
    expect(cubit.state.presets['Watchlist']?.favorite, isTrue);
    await cubit.close();
  });

  test('should reset filters without clearing presets or decisions', () async {
    final cubit = _cubit(FakeDiscoverySelector(null));
    await cubit.replaceCandidates(<CatalogCandidate>[
      _candidate('liked'),
      _candidate('rejected'),
    ]);
    await cubit.like('liked');
    await cubit.reject('rejected');
    await cubit.updateFilter(const CatalogFilter(favorite: true));
    await cubit.savePreset('Favorites');

    await cubit.resetFilters();

    expect(cubit.state.filter, const CatalogFilter());
    expect(cubit.state.presets['Favorites']?.favorite, isTrue);
    expect(cubit.state.likedIds, contains('liked'));
    expect(cubit.state.rejectedIds, contains('rejected'));
    await cubit.close();
  });

  test(
    'should keep one recent-window anchor across state evaluations',
    () async {
      final anchor = DateTime.utc(2026, 8, 11, 12);
      final cubit = DiscoveryCubit(
        store: FakeDiscoveryStore(),
        scopeKey: 'server/user',
        selector: FakeDiscoverySelector(null),
        now: () => anchor,
      );
      await cubit.updateFilter(
        const CatalogFilter(addedWithin: CatalogAddedWindow.sevenDays),
      );
      await cubit.replaceCandidates(<CatalogCandidate>[
        CatalogCandidate(
          id: 'boundary',
          name: 'Boundary',
          mediaType: CatalogMediaType.movie,
          dateCreated: anchor.subtract(const Duration(days: 7)),
          poster: const CatalogImage.fallback(),
          backdrop: const CatalogImage.fallback(),
        ),
      ]);

      expect(cubit.state.filter.dateWindowAnchor, anchor);
      expect(cubit.state.filteredCandidates.single.id, 'boundary');
      expect(cubit.state.filteredCandidates.single.id, 'boundary');
      await cubit.close();
    },
  );

  test('should validate preset names and bound preset count', () async {
    final cubit = _cubit(FakeDiscoverySelector(null));
    expect(() => cubit.savePreset('   '), throwsArgumentError);
    for (var index = 0; index < 25; index++) {
      await cubit.savePreset('Preset $index');
    }

    expect(cubit.state.presets.length, lessThanOrEqualTo(20));
    await cubit.close();
  });

  test('should hydrate state across a new cubit instance', () async {
    final store = FakeDiscoveryStore();
    final restoredAnchor = DateTime.utc(2026, 8, 11, 12);
    final first = DiscoveryCubit(
      store: store,
      scopeKey: 'server/user',
      selector: FakeDiscoverySelector(null),
    );
    await first.replaceCandidates(<CatalogCandidate>[_candidate('movie-1')]);
    await first.like('movie-1');
    await first.updateFilter(
      const CatalogFilter(
        searchTerm: 'movie',
        addedWithin: CatalogAddedWindow.ninetyDays,
        sort: CatalogSort.recentlyAdded,
        officialRatings: <String>{'PG-13'},
        seriesStatuses: <CatalogSeriesStatus>{CatalogSeriesStatus.ended},
        watched: true,
      ),
    );
    await first.setMode(DiscoveryMode.swipe);
    await first.close();

    final second = DiscoveryCubit(
      store: store,
      scopeKey: 'server/user',
      selector: FakeDiscoverySelector(null),
      now: () => restoredAnchor,
    );
    await second.hydrate();

    expect(second.state.isHydrated, isTrue);
    expect(second.state.filter.watched, isTrue);
    expect(second.state.filter.searchTerm, 'movie');
    expect(second.state.filter.addedWithin, CatalogAddedWindow.ninetyDays);
    expect(second.state.filter.sort, CatalogSort.recentlyAdded);
    expect(second.state.filter.officialRatings, <String>{'PG-13'});
    expect(second.state.filter.seriesStatuses, <CatalogSeriesStatus>{
      CatalogSeriesStatus.ended,
    });
    expect(second.state.filter.dateWindowAnchor, restoredAnchor);
    expect(second.state.likedIds, contains('movie-1'));
    expect(second.state.mode, DiscoveryMode.swipe);
    await second.close();
  });

  test(
    'should restore filters presets recent picks and dismissals together',
    () async {
      final store = FakeDiscoveryStore();
      final first = DiscoveryCubit(
        store: store,
        scopeKey: 'server/user',
        selector: FakeDiscoverySelector('movie-2'),
      );
      await first.replaceCandidates(<CatalogCandidate>[
        _candidate('movie-1'),
        _candidate('movie-2'),
      ]);
      await first.updateFilter(const CatalogFilter(favorite: true));
      await first.savePreset('Favorites');
      await first.updateFilter(const CatalogFilter());
      await first.dismiss('movie-1');
      await first.revealNext();
      await first.close();

      final second = DiscoveryCubit(
        store: store,
        scopeKey: 'server/user',
        selector: FakeDiscoverySelector(null),
      );
      await second.hydrate();

      expect(
        (
          filterFavorite: second.state.filter.favorite,
          presetFavorite: second.state.presets['Favorites']?.favorite,
          recentPicks: second.state.recentPickIds.join(','),
          dismissals: (second.state.rejectedIds.toList()..sort()).join(','),
        ),
        (
          filterFavorite: null,
          presetFavorite: true,
          recentPicks: 'movie-2',
          dismissals: 'movie-1',
        ),
      );
      await second.close();
    },
  );

  test('should clear only discovery state and persistence namespace', () async {
    final store = FakeDiscoveryStore();
    final cubit = DiscoveryCubit(
      store: store,
      scopeKey: 'server/user',
      selector: FakeDiscoverySelector(null),
    );
    await cubit.like('movie-1');
    await cubit.clearDiscovery();

    expect(cubit.state.likedIds, isEmpty);
    expect(store.clearCount, 1);
    expect(store.lastScope, 'server/user');
    await cubit.close();
  });

  test('should ignore late hydration after a user mutation', () async {
    final store = ControlledDiscoveryStore();
    final cubit = DiscoveryCubit(
      store: store,
      scopeKey: 'server/user',
      selector: FakeDiscoverySelector(null),
    );
    final hydration = cubit.hydrate();
    await Future<void>.delayed(Duration.zero);
    await cubit.replaceCandidates(<CatalogCandidate>[
      _candidate('user-choice'),
    ]);
    await cubit.like('user-choice');
    store.readCompleter.complete(
      const DiscoverySnapshot(likedIds: <String>{'stale-choice'}),
    );
    await hydration;

    expect(cubit.state.likedIds, <String>{'user-choice'});
    await cubit.close();
  });

  test('should not resurrect a delayed save after clear completes', () async {
    final store = FakeDiscoveryStore()
      ..writeDelay = const Duration(milliseconds: 10);
    final cubit = DiscoveryCubit(
      store: store,
      scopeKey: 'server/user',
      selector: FakeDiscoverySelector(null),
    );
    final save = cubit.replaceCandidates(<CatalogCandidate>[
      _candidate('movie'),
    ]);
    await Future<void>.delayed(Duration.zero);
    final clear = cubit.clearDiscovery();
    await Future.wait(<Future<void>>[save, clear]);

    expect(store.snapshot, isNull);
    await cubit.close();
  });

  test(
    'should hydrate after queued writes instead of reading stale state',
    () async {
      final store = FakeDiscoveryStore()
        ..snapshot = const DiscoverySnapshot(
          filter: CatalogFilter(watched: false),
        )
        ..writeDelay = const Duration(milliseconds: 10);
      final cubit = DiscoveryCubit(
        store: store,
        scopeKey: 'server/user',
        selector: FakeDiscoverySelector(null),
      );

      final save = cubit.updateFilter(const CatalogFilter(favorite: true));
      final hydration = cubit.hydrate();
      await Future.wait(<Future<void>>[save, hydration]);

      expect(cubit.state.filter.favorite, isTrue);
      await cubit.close();
    },
  );

  test(
    'should surface a typed persistence error when clearing fails',
    () async {
      final store = FailingDiscoveryStore();
      final cubit = DiscoveryCubit(
        store: store,
        scopeKey: 'server/user',
        selector: FakeDiscoverySelector(null),
      );

      await cubit.clearDiscovery();

      expect(store.clearCalls, 1);
      expect(cubit.state.persistenceError, isTrue);
      expect(cubit.state.likedIds, isEmpty);
      await cubit.close();
    },
  );

  test(
    'should aggregate 2,000 candidates without duplicate eligibility',
    () async {
      final cubit = _cubit(FakeDiscoverySelector(null));
      final candidates = List<CatalogCandidate>.generate(
        2000,
        (index) => _candidate('movie-$index'),
      );
      await cubit.replaceCandidates(candidates);

      expect(cubit.state.candidates, hasLength(2000));
      expect(cubit.state.eligibleCandidates, hasLength(2000));
      await cubit.close();
    },
  );
}

final class FailingDiscoveryStore implements DiscoveryStore {
  int clearCalls = 0;

  @override
  Future<DiscoverySnapshot?> read(String scope) async => null;

  @override
  Future<void> write(String scope, DiscoverySnapshot snapshot) async {}

  @override
  Future<void> clear(String scope) async {
    clearCalls++;
    throw StateError('clear failed');
  }
}

DiscoveryCubit _cubit(DiscoverySelector selector) => DiscoveryCubit(
  store: FakeDiscoveryStore(),
  scopeKey: 'server/user',
  selector: selector,
);

CatalogCandidate _candidate(
  String id, {
  CatalogMediaType type = CatalogMediaType.movie,
  bool? watched,
  bool? favorite,
}) => CatalogCandidate(
  id: id,
  name: id,
  mediaType: type,
  watched: watched,
  favorite: favorite,
  poster: const CatalogImage.fallback(),
  backdrop: const CatalogImage.fallback(),
);
