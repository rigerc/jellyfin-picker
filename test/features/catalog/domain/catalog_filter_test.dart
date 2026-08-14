import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_filter.dart';

void main() {
  test('should include a candidate at every inclusive filter boundary', () {
    const candidate = CatalogCandidate(
      id: 'movie-1',
      name: 'Candy Movie',
      mediaType: CatalogMediaType.movie,
      year: 2024,
      runtimeMinutes: 120,
      genres: <String>{'Drama', 'Candy'},
      communityRating: 8,
      criticRating: 7,
      watched: true,
      favorite: true,
      poster: CatalogImage.fallback(),
      backdrop: CatalogImage.fallback(),
    );

    const filter = CatalogFilter(
      mediaTypes: <CatalogMediaType>{CatalogMediaType.movie},
      minimumRuntimeMinutes: 120,
      maximumRuntimeMinutes: 120,
      minimumCommunityRating: 8,
      maximumCommunityRating: 8,
      minimumCriticRating: 7,
      maximumCriticRating: 7,
      genres: <String>{'Drama', 'Candy'},
      decades: <int>{2020},
      watched: true,
      favorite: true,
    );

    expect(filter.matches(candidate), isTrue);
  });

  test('should require every selected genre while combining dimensions', () {
    const candidate = CatalogCandidate(
      id: 'movie-1',
      name: 'Movie',
      mediaType: CatalogMediaType.movie,
      genres: <String>{'Drama'},
      poster: CatalogImage.fallback(),
      backdrop: CatalogImage.fallback(),
    );

    expect(
      const CatalogFilter(
        mediaTypes: <CatalogMediaType>{CatalogMediaType.series},
      ).matches(candidate),
      isFalse,
    );
    expect(
      const CatalogFilter(
        genres: <String>{'Drama', 'Comedy'},
      ).matches(candidate),
      isFalse,
    );
    expect(
      const CatalogFilter(genres: <String>{'Drama'}).matches(candidate),
      isTrue,
    );
  });

  test('should not satisfy active constraints with missing metadata', () {
    const candidate = CatalogCandidate(
      id: 'missing',
      name: 'Missing',
      mediaType: CatalogMediaType.movie,
      poster: CatalogImage.fallback(),
      backdrop: CatalogImage.fallback(),
    );

    expect(
      const CatalogFilter(minimumRuntimeMinutes: 1).matches(candidate),
      isFalse,
    );
    expect(const CatalogFilter().matches(candidate), isTrue);
  });

  test('should compare selected genres without case sensitivity', () {
    const candidate = CatalogCandidate(
      id: 'movie',
      name: 'Movie',
      mediaType: CatalogMediaType.movie,
      genres: <String>{'drama', 'COMEDY'},
      poster: CatalogImage.fallback(),
      backdrop: CatalogImage.fallback(),
    );

    expect(
      const CatalogFilter(
        genres: <String>{'Comedy', 'DRAMA'},
      ).matches(candidate),
      isTrue,
    );
    expect(
      const CatalogFilter(genres: <String>{'Horror'}).matches(candidate),
      isFalse,
    );
  });

  test('should enforce inclusive and exclusive numeric boundaries', () {
    const candidate = CatalogCandidate(
      id: 'movie',
      name: 'Movie',
      mediaType: CatalogMediaType.movie,
      year: 2019,
      runtimeMinutes: 100,
      communityRating: 8,
      criticRating: 7,
      watched: false,
      favorite: true,
      poster: CatalogImage.fallback(),
      backdrop: CatalogImage.fallback(),
    );
    const inclusive = <CatalogFilter>[
      CatalogFilter(minimumRuntimeMinutes: 100),
      CatalogFilter(maximumRuntimeMinutes: 100),
      CatalogFilter(minimumCommunityRating: 8),
      CatalogFilter(maximumCriticRating: 7),
    ];
    const outside = <CatalogFilter>[
      CatalogFilter(minimumRuntimeMinutes: 101),
      CatalogFilter(maximumRuntimeMinutes: 99),
      CatalogFilter(minimumCommunityRating: 9),
      CatalogFilter(maximumCriticRating: 6),
    ];

    expect(inclusive.every((filter) => filter.matches(candidate)), isTrue);
    expect(outside.every((filter) => !filter.matches(candidate)), isTrue);
  });

  test('should enforce every rating boundary in both directions', () {
    const candidate = CatalogCandidate(
      id: 'movie',
      name: 'Movie',
      mediaType: CatalogMediaType.movie,
      communityRating: 8,
      criticRating: 7,
      poster: CatalogImage.fallback(),
      backdrop: CatalogImage.fallback(),
    );
    final cases = <CatalogFilter, bool>{
      const CatalogFilter(minimumCommunityRating: 7): true,
      const CatalogFilter(minimumCommunityRating: 8): true,
      const CatalogFilter(minimumCommunityRating: 9): false,
      const CatalogFilter(maximumCommunityRating: 9): true,
      const CatalogFilter(maximumCommunityRating: 8): true,
      const CatalogFilter(maximumCommunityRating: 7): false,
      const CatalogFilter(minimumCriticRating: 6): true,
      const CatalogFilter(minimumCriticRating: 7): true,
      const CatalogFilter(minimumCriticRating: 8): false,
      const CatalogFilter(maximumCriticRating: 8): true,
      const CatalogFilter(maximumCriticRating: 7): true,
      const CatalogFilter(maximumCriticRating: 6): false,
    };

    for (final entry in cases.entries) {
      expect(
        entry.key.matches(candidate),
        entry.value,
        reason: entry.key.toString(),
      );
    }
  });

  test(
    'should enforce decade edges, media selections, and tri-state flags',
    () {
      const candidate = CatalogCandidate(
        id: 'movie',
        name: 'Movie',
        mediaType: CatalogMediaType.movie,
        year: 2020,
        watched: false,
        favorite: true,
        poster: CatalogImage.fallback(),
        backdrop: CatalogImage.fallback(),
      );

      expect(
        const CatalogFilter(decades: <int>{2020}).matches(candidate),
        isTrue,
      );
      expect(
        const CatalogFilter(decades: <int>{2010}).matches(candidate),
        isFalse,
      );
      expect(
        const CatalogFilter(
          mediaTypes: <CatalogMediaType>{CatalogMediaType.movie},
        ).matches(candidate),
        isTrue,
      );
      expect(const CatalogFilter(watched: false).matches(candidate), isTrue);
      expect(const CatalogFilter(watched: true).matches(candidate), isFalse);
      expect(const CatalogFilter(favorite: true).matches(candidate), isTrue);
      expect(const CatalogFilter(favorite: false).matches(candidate), isFalse);
    },
  );

  test('should classify every decade edge into its decade bucket', () {
    const years = <int>[1979, 1980, 1989, 1990];
    final expectedDecades = <int>[1970, 1980, 1980, 1990];

    for (var index = 0; index < years.length; index++) {
      final candidate = CatalogCandidate(
        id: 'movie-$index',
        name: 'Movie',
        mediaType: CatalogMediaType.movie,
        year: years[index],
        poster: const CatalogImage.fallback(),
        backdrop: const CatalogImage.fallback(),
      );
      expect(
        CatalogFilter(
          decades: <int>{expectedDecades[index]},
        ).matches(candidate),
        isTrue,
      );
      expect(
        CatalogFilter(
          decades: <int>{expectedDecades[index] + 10},
        ).matches(candidate),
        isFalse,
      );
    }
  });

  test(
    'should reject every active dimension when its candidate value is null',
    () {
      const candidate = CatalogCandidate(
        id: 'missing',
        name: 'Missing',
        mediaType: CatalogMediaType.movie,
        poster: CatalogImage.fallback(),
        backdrop: CatalogImage.fallback(),
      );
      const filters = <CatalogFilter>[
        CatalogFilter(minimumCommunityRating: 1),
        CatalogFilter(minimumCriticRating: 1),
        CatalogFilter(genres: <String>{'Drama'}),
        CatalogFilter(decades: <int>{2020}),
        CatalogFilter(watched: false),
        CatalogFilter(favorite: false),
      ];

      expect(filters.every((filter) => !filter.matches(candidate)), isTrue);
    },
  );

  test(
    'should report search, date window, and metadata dimensions as active',
    () {
      expect(
        const CatalogFilter(
          searchTerm: 'movie',
          addedWithin: CatalogAddedWindow.sevenDays,
          officialRatings: <String>{'PG'},
        ).isActive,
        isTrue,
      );
      expect(const CatalogFilter(sort: CatalogSort.title).isActive, isFalse);
    },
  );

  test('should match a normalized title and inclusive added date cutoff', () {
    final now = DateTime.utc(2025, 2, 8, 12);
    final candidate = CatalogCandidate(
      id: 'movie',
      name: '  The   Candy Movie  ',
      mediaType: CatalogMediaType.movie,
      dateCreated: DateTime.utc(2025, 2, 1, 12),
      poster: CatalogImage.fallback(),
      backdrop: CatalogImage.fallback(),
    );

    expect(
      const CatalogFilter(
        searchTerm: 'candy movie',
        addedWithin: CatalogAddedWindow.sevenDays,
      ).matches(candidate, now: now),
      isTrue,
    );
  });

  test('should reuse its date-window anchor across repeated evaluations', () {
    final anchor = DateTime.utc(2025, 2, 8, 12);
    final candidate = CatalogCandidate(
      id: 'movie',
      name: 'Movie',
      mediaType: CatalogMediaType.movie,
      dateCreated: anchor.subtract(const Duration(days: 7)),
      poster: CatalogImage.fallback(),
      backdrop: CatalogImage.fallback(),
    );
    final filter = CatalogFilter(
      addedWithin: CatalogAddedWindow.sevenDays,
      dateWindowAnchor: anchor,
    );

    expect(filter.matches(candidate), isTrue);
    expect(filter.matches(candidate), isTrue);
  });

  test('should enforce every recent window at its inclusive UTC boundary', () {
    final anchor = DateTime.parse('2025-02-08T13:00:00+01:00');
    for (final window in CatalogAddedWindow.values) {
      final cutoff = anchor.toUtc().subtract(Duration(days: window.days));
      final candidate = CatalogCandidate(
        id: window.name,
        name: 'Movie',
        mediaType: CatalogMediaType.movie,
        dateCreated: cutoff,
        poster: CatalogImage.fallback(),
        backdrop: CatalogImage.fallback(),
      );
      final filter = CatalogFilter(
        addedWithin: window,
        dateWindowAnchor: anchor,
      );

      expect(filter.matches(candidate), isTrue, reason: window.name);
      expect(
        filter.matches(
          CatalogCandidate(
            id: '${window.name}-old',
            name: 'Old movie',
            mediaType: CatalogMediaType.movie,
            dateCreated: cutoff.subtract(const Duration(microseconds: 1)),
            poster: CatalogImage.fallback(),
            backdrop: CatalogImage.fallback(),
          ),
        ),
        isFalse,
        reason: window.name,
      );
    }
  });

  test('should reject a title outside an active date window or search', () {
    final now = DateTime.utc(2025, 2, 8, 12);
    final candidate = CatalogCandidate(
      id: 'movie',
      name: 'Other Movie',
      mediaType: CatalogMediaType.movie,
      dateCreated: DateTime.utc(2025, 1, 31),
      poster: CatalogImage.fallback(),
      backdrop: CatalogImage.fallback(),
    );

    expect(
      const CatalogFilter(
        searchTerm: 'candy',
        addedWithin: CatalogAddedWindow.sevenDays,
      ).matches(candidate, now: now),
      isFalse,
    );
  });

  test('should match official ratings without case sensitivity', () {
    const candidate = CatalogCandidate(
      id: 'movie',
      name: 'Movie',
      mediaType: CatalogMediaType.movie,
      officialRating: 'pg-13',
      poster: CatalogImage.fallback(),
      backdrop: CatalogImage.fallback(),
    );

    expect(
      const CatalogFilter(
        officialRatings: <String>{'PG-13'},
      ).matches(candidate),
      isTrue,
    );
  });

  test('should reject a series even when no filters are active', () {
    const series = CatalogCandidate(
      id: 'series',
      name: 'Series',
      mediaType: CatalogMediaType.series,
      poster: CatalogImage.fallback(),
      backdrop: CatalogImage.fallback(),
    );

    expect(const CatalogFilter().matches(series), isFalse);
  });

  test('should clear nullable constraints when copying a filter', () {
    const filter = CatalogFilter(
      addedWithin: CatalogAddedWindow.thirtyDays,
      minimumRuntimeMinutes: 10,
      watched: true,
    );

    final cleared = filter.copyWith(
      addedWithin: null,
      minimumRuntimeMinutes: null,
      watched: null,
    );

    expect(cleared.addedWithin, isNull);
    expect(cleared.minimumRuntimeMinutes, isNull);
    expect(cleared.watched, isNull);
  });
}
