enum CatalogMediaType { movie, series }

final class CatalogImage {
  const CatalogImage({
    required this.uri,
    required this.isFallback,
    required this.aspectRatio,
  });

  const CatalogImage.fallback()
    : uri = null,
      isFallback = true,
      aspectRatio = 0.67;

  final Uri? uri;
  final bool isFallback;
  final double aspectRatio;

  Uri? variantUri({required int maxWidth, required int quality, int? blur}) {
    final source = uri;
    if (source == null || isFallback) {
      return null;
    }
    return source.replace(
      queryParameters: <String, String>{
        ...source.queryParameters,
        'maxWidth': '$maxWidth',
        'quality': '$quality',
        if (blur != null) 'blur': '$blur',
      },
    );
  }
}

final class CatalogCandidate {
  const CatalogCandidate({
    required this.id,
    required this.name,
    required this.mediaType,
    required this.poster,
    required this.backdrop,
    this.year,
    this.dateCreated,
    this.runtimeMinutes,
    Set<String> genres = const <String>{},
    this.communityRating,
    this.criticRating,
    this.officialRating,
    this.status,
    this.overview,
    List<String> cast = const <String>[],
    this.watched,
    this.favorite,
  }) : // Public constructor names intentionally differ from backing fields.
       // ignore: prefer_initializing_formals
       _genres = genres,
       // Public constructor names intentionally differ from backing fields.
       // ignore: prefer_initializing_formals
       _cast = cast;

  final String id;
  final String name;
  final CatalogMediaType mediaType;
  final int? year;
  final DateTime? dateCreated;
  final int? runtimeMinutes;
  final Set<String> _genres;
  final double? communityRating;
  final double? criticRating;
  final String? officialRating;
  final String? status;
  final String? overview;
  final List<String> _cast;
  final bool? watched;
  final bool? favorite;
  final CatalogImage poster;
  final CatalogImage backdrop;

  Set<String> get genres => Set<String>.unmodifiable(_genres);

  List<String> get cast => List<String>.unmodifiable(_cast);

  CatalogCandidate copyWith({Object? dateCreated = _unset, bool? favorite}) =>
      CatalogCandidate(
        id: id,
        name: name,
        mediaType: mediaType,
        year: year,
        dateCreated: _copyDate(dateCreated, this.dateCreated),
        runtimeMinutes: runtimeMinutes,
        genres: _genres,
        communityRating: communityRating,
        criticRating: criticRating,
        officialRating: officialRating,
        status: status,
        overview: overview,
        cast: _cast,
        watched: watched,
        favorite: favorite ?? this.favorite,
        poster: poster,
        backdrop: backdrop,
      );

  static DateTime? _copyDate(Object? value, DateTime? current) =>
      identical(value, _unset)
      ? current
      : value is DateTime
      ? value
      : null;
}

const _unset = Object();
