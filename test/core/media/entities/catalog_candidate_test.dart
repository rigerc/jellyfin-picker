import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';

void main() {
  test(
    'should build bounded image variants while preserving the cache tag',
    () {
      final image = CatalogImage(
        uri: Uri.parse(
          'https://example.test/Items/movie-1/Images/Primary?tag=poster-tag',
        ),
        isFallback: false,
        aspectRatio: 0.67,
      );

      final preview = image.variantUri(maxWidth: 48, quality: 35, blur: 20);
      final display = image.variantUri(maxWidth: 600, quality: 90);

      expect(preview?.queryParameters, <String, String>{
        'tag': 'poster-tag',
        'maxWidth': '48',
        'quality': '35',
        'blur': '20',
      });
      expect(display?.queryParameters, <String, String>{
        'tag': 'poster-tag',
        'maxWidth': '600',
        'quality': '90',
      });
    },
  );

  test('should replace only favorite when copying a candidate', () {
    final candidate = CatalogCandidate(
      id: 'movie-1',
      name: 'Movie',
      mediaType: CatalogMediaType.movie,
      year: 2025,
      runtimeMinutes: 123,
      genres: <String>{'Drama'},
      communityRating: 8.1,
      criticRating: 7.4,
      officialRating: 'PG-13',
      status: 'Released',
      overview: 'Overview',
      cast: <String>['Actor'],
      watched: true,
      favorite: false,
      poster: const CatalogImage.fallback(),
      backdrop: const CatalogImage.fallback(),
    );

    final updated = candidate.copyWith(favorite: true);

    expect(
      (
        originalFavorite: candidate.favorite,
        updatedFavorite: updated.favorite,
        watched: updated.watched,
        id: updated.id,
        name: updated.name,
        year: updated.year,
        runtime: updated.runtimeMinutes,
        genres: updated.genres.join(','),
        communityRating: updated.communityRating,
        criticRating: updated.criticRating,
        officialRating: updated.officialRating,
        status: updated.status,
        overview: updated.overview,
        cast: updated.cast.join(','),
      ),
      (
        originalFavorite: false,
        updatedFavorite: true,
        watched: true,
        id: 'movie-1',
        name: 'Movie',
        year: 2025,
        runtime: 123,
        genres: 'Drama',
        communityRating: 8.1,
        criticRating: 7.4,
        officialRating: 'PG-13',
        status: 'Released',
        overview: 'Overview',
        cast: 'Actor',
      ),
    );
  });
}
