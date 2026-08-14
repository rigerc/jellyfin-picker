import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_snapshot.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_state.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_mode.dart';
import 'package:jellyfin_picker/features/discovery/domain/serialization/catalog_filter_codec.dart';

void main() {
  test('should round trip every catalog filter field', () {
    const filter = CatalogFilter(
      mediaTypes: <CatalogMediaType>{CatalogMediaType.movie},
      minimumRuntimeMinutes: 10,
      maximumRuntimeMinutes: 180,
      minimumCommunityRating: 6.5,
      maximumCommunityRating: 9.5,
      minimumCriticRating: 5.5,
      maximumCriticRating: 8.5,
      genres: <String>{'Drama', 'Comedy'},
      decades: <int>{1980, 2020},
      watched: true,
      favorite: false,
      searchTerm: ' candy ',
      addedWithin: CatalogAddedWindow.ninetyDays,
      sort: CatalogSort.recentlyAdded,
      officialRatings: <String>{'PG-13'},
    );

    final encoded = CatalogFilterCodec.encode(filter);
    final decoded = CatalogFilterCodec.decode(encoded);

    expect(CatalogFilterCodec.encode(decoded!), encoded);
  });

  test('should discard legacy TV constraints while restoring movies', () {
    final decoded = CatalogFilterCodec.decode(<String, Object?>{
      'mediaTypes': <String>['movie', 'series'],
      'minimumRuntimeMinutes': null,
      'maximumRuntimeMinutes': null,
      'minimumCommunityRating': null,
      'maximumCommunityRating': null,
      'minimumCriticRating': null,
      'maximumCriticRating': null,
      'genres': <String>[],
      'decades': <int>[],
      'seriesStatuses': <String>['continuing'],
      'watched': null,
      'favorite': null,
    });

    expect(decoded?.mediaTypes, <CatalogMediaType>{CatalogMediaType.movie});
    expect(decoded?.seriesStatuses, isEmpty);
  });

  test('should restore old filter snapshots with new defaults', () {
    final decoded = CatalogFilterCodec.decode(<String, Object?>{
      'mediaTypes': <String>[],
      'minimumRuntimeMinutes': null,
      'maximumRuntimeMinutes': null,
      'minimumCommunityRating': null,
      'maximumCommunityRating': null,
      'minimumCriticRating': null,
      'maximumCriticRating': null,
      'genres': <String>[],
      'decades': <int>[],
      'watched': null,
      'favorite': null,
    });

    expect(decoded?.searchTerm, isEmpty);
    expect(decoded?.addedWithin, isNull);
    expect(decoded?.sort, CatalogSort.defaultOrder);
    expect(decoded?.officialRatings, isEmpty);
    expect(decoded?.seriesStatuses, isEmpty);
  });

  test('should accept critic ratings up to one hundred', () {
    final decoded = CatalogFilterCodec.decode(<String, Object?>{
      'mediaTypes': <String>[],
      'minimumRuntimeMinutes': null,
      'maximumRuntimeMinutes': null,
      'minimumCommunityRating': null,
      'maximumCommunityRating': null,
      'minimumCriticRating': 100,
      'maximumCriticRating': 100,
      'genres': <String>[],
      'decades': <int>[],
      'watched': null,
      'favorite': null,
    });

    expect(decoded?.maximumCriticRating, 100);
  });

  test('should reject malformed filter data without throwing', () {
    final decoded = CatalogFilterCodec.decode(<String, Object?>{
      'mediaTypes': <Object?>['unknown'],
    });

    expect(decoded, isNull);
  });

  test('should serialize continuity without catalog media payloads', () {
    const snapshot = DiscoverySnapshot(
      filter: CatalogFilter(
        mediaTypes: <CatalogMediaType>{CatalogMediaType.movie},
      ),
      presets: <String, CatalogFilter>{
        'Favorites': CatalogFilter(favorite: true),
      },
      likedIds: <String>{'liked'},
      rejectedIds: <String>{'rejected'},
      recentPickIds: <String>['liked'],
      mode: DiscoveryMode.shuffle,
      position: 4,
      currentRevealId: 'liked',
      currentPickId: 'liked',
    );

    final json = snapshot.toJson();
    final restored = DiscoverySnapshot.fromJson(json);

    expect(restored, snapshot);
    expect(json.toString(), isNot(contains('poster')));
    expect(json.toString(), isNot(contains('token')));
  });

  test('should preserve hash equality after a snapshot round trip', () {
    const snapshot = DiscoverySnapshot(
      filter: CatalogFilter(favorite: true),
      presets: <String, CatalogFilter>{
        'Movies': CatalogFilter(
          mediaTypes: <CatalogMediaType>{CatalogMediaType.movie},
        ),
      },
      likedIds: <String>{'liked'},
      rejectedIds: <String>{'rejected'},
      recentPickIds: <String>['liked'],
    );

    final restored = DiscoverySnapshot.fromJson(snapshot.toJson());

    expect(restored.hashCode, snapshot.hashCode);
  });

  test('should recover from unsupported snapshot versions', () {
    final restored = DiscoverySnapshot.fromJson(<String, Object?>{
      'version': 999,
    });

    expect(restored, isNull);
  });

  test('should normalize overlapping and invalid decision IDs', () {
    final restored = DiscoverySnapshot.fromJson(<String, Object?>{
      'version': 1,
      'filter': CatalogFilterCodec.encode(const CatalogFilter()),
      'presets': <String, Object?>{},
      'likedIds': <String>['liked', 'shared', ''],
      'rejectedIds': <String>['shared', 'rejected', ''],
      'recentPickIds': <String>['liked', 'shared', ''],
      'mode': 'grid',
      'position': 0,
      'currentRevealId': '',
      'currentPickId': '',
    });

    expect(restored?.likedIds, <String>{'liked'});
    expect(restored?.rejectedIds, <String>{'shared', 'rejected'});
    expect(restored?.recentPickIds, <String>['liked']);
    expect(restored?.currentRevealId, isNull);
    expect(restored?.currentPickId, isNull);
  });

  test('should reject oversized and invalid snapshot collections', () {
    final presets = <String, Object?>{
      for (var index = 0; index < 21; index++)
        'Preset $index': CatalogFilterCodec.encode(const CatalogFilter()),
    };
    final restored = DiscoverySnapshot.fromJson(<String, Object?>{
      'version': 1,
      'filter': CatalogFilterCodec.encode(const CatalogFilter()),
      'presets': presets,
      'likedIds': List<String>.generate(101, (index) => 'liked-$index'),
      'rejectedIds': <String>[],
      'recentPickIds': <String>[],
      'mode': 'grid',
      'position': 0,
    });

    expect(restored, isNull);
  });

  test(
    'should normalize valid preset names and reject invalid filter ranges',
    () {
      final restored = DiscoverySnapshot.fromJson(<String, Object?>{
        'version': 1,
        'filter': <String, Object?>{
          'mediaTypes': <String>[],
          'minimumRuntimeMinutes': 90,
          'maximumRuntimeMinutes': 10,
          'minimumCommunityRating': null,
          'maximumCommunityRating': null,
          'minimumCriticRating': null,
          'maximumCriticRating': null,
          'genres': <String>[],
          'decades': <int>[2020],
          'watched': null,
          'favorite': null,
        },
        'presets': <String, Object?>{
          '  Saved  ': CatalogFilterCodec.encode(const CatalogFilter()),
        },
        'likedIds': <String>[],
        'rejectedIds': <String>[],
        'recentPickIds': <String>[],
        'mode': 'grid',
        'position': 0,
      });

      expect(restored, isNull);
    },
  );

  test('should compute shortlist and undecided eligibility immutably', () {
    const movie = CatalogCandidate(
      id: 'movie',
      name: 'Movie',
      mediaType: CatalogMediaType.movie,
      poster: CatalogImage.fallback(),
      backdrop: CatalogImage.fallback(),
    );
    const series = CatalogCandidate(
      id: 'series',
      name: 'Series',
      mediaType: CatalogMediaType.series,
      poster: CatalogImage.fallback(),
      backdrop: CatalogImage.fallback(),
    );
    final state = DiscoveryState(
      candidates: <CatalogCandidate>[movie, series],
      likedIds: <String>{'movie'},
      rejectedIds: <String>{'series'},
    );

    expect(state.undecidedCandidates, isEmpty);
    expect(state.eligibleCandidates.map((candidate) => candidate.id), <String>[
      'movie',
    ]);
  });

  test('should let rejected decisions win over likes', () {
    final state = DiscoveryState(
      candidates: <CatalogCandidate>[_candidate('shared'), _candidate('liked')],
      likedIds: <String>{'shared', 'liked'},
      rejectedIds: <String>{'shared'},
    );

    expect(state.eligibleCandidates.map((item) => item.id), <String>['liked']);
  });

  test('should defensively copy mutable discovery collections', () {
    final candidates = <CatalogCandidate>[_candidate('movie')];
    final likedIds = <String>{'movie'};
    final presets = <String, CatalogFilter>{
      'Saved': const CatalogFilter(favorite: true),
    };
    final state = DiscoveryState(
      candidates: candidates,
      likedIds: likedIds,
      presets: presets,
    );
    candidates.clear();
    likedIds.clear();
    presets.clear();

    expect(state.candidates, hasLength(1));
    expect(state.likedIds, contains('movie'));
    expect(state.presets, contains('Saved'));
  });

  test('should prevent nested candidate and filter mutation', () {
    final state = DiscoveryState(
      candidates: <CatalogCandidate>[
        CatalogCandidate(
          id: 'movie',
          name: 'movie',
          mediaType: CatalogMediaType.movie,
          genres: <String>{'Drama'},
          cast: <String>['Actor'],
          poster: const CatalogImage.fallback(),
          backdrop: const CatalogImage.fallback(),
        ),
      ],
      filter: const CatalogFilter(genres: <String>{'Drama'}),
      presets: const <String, CatalogFilter>{
        'Saved': CatalogFilter(genres: <String>{'Drama'}),
      },
    );

    expect(
      () => state.candidates.single.genres.add('Comedy'),
      throwsUnsupportedError,
    );
    expect(
      () => state.candidates.single.cast.add('Actor 2'),
      throwsUnsupportedError,
    );
    expect(() => state.filter.genres.add('Comedy'), throwsUnsupportedError);
    final saved = state.presets['Saved'];
    expect(saved, isNotNull);
    if (saved != null) {
      expect(() => saved.genres.add('Comedy'), throwsUnsupportedError);
    }
  });
}

CatalogCandidate _candidate(String id) => CatalogCandidate(
  id: id,
  name: id,
  mediaType: CatalogMediaType.movie,
  poster: const CatalogImage.fallback(),
  backdrop: const CatalogImage.fallback(),
);
