import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';

/// Filter dimensions are ANDed; values selected inside one dimension are ORed.
final class CatalogFilter {
  const CatalogFilter({
    Set<CatalogMediaType> mediaTypes = const <CatalogMediaType>{},
    this.minimumRuntimeMinutes,
    this.maximumRuntimeMinutes,
    this.minimumCommunityRating,
    this.maximumCommunityRating,
    this.minimumCriticRating,
    this.maximumCriticRating,
    Set<String> genres = const <String>{},
    Set<int> decades = const <int>{},
    this.watched,
    this.favorite,
  }) : // Public constructor names intentionally differ from backing fields.
       // ignore: prefer_initializing_formals
       _mediaTypes = mediaTypes,
       // Public constructor names intentionally differ from backing fields.
       // ignore: prefer_initializing_formals
       _genres = genres,
       // Public constructor names intentionally differ from backing fields.
       // ignore: prefer_initializing_formals
       _decades = decades;

  final Set<CatalogMediaType> _mediaTypes;
  final int? minimumRuntimeMinutes;
  final int? maximumRuntimeMinutes;
  final double? minimumCommunityRating;
  final double? maximumCommunityRating;
  final double? minimumCriticRating;
  final double? maximumCriticRating;
  final Set<String> _genres;
  final Set<int> _decades;
  final bool? watched;
  final bool? favorite;

  Set<CatalogMediaType> get mediaTypes =>
      Set<CatalogMediaType>.unmodifiable(_mediaTypes);

  Set<String> get genres => Set<String>.unmodifiable(_genres);

  Set<int> get decades => Set<int>.unmodifiable(_decades);

  bool get isActive =>
      mediaTypes.isNotEmpty ||
      minimumRuntimeMinutes != null ||
      maximumRuntimeMinutes != null ||
      minimumCommunityRating != null ||
      maximumCommunityRating != null ||
      minimumCriticRating != null ||
      maximumCriticRating != null ||
      genres.isNotEmpty ||
      decades.isNotEmpty ||
      watched != null ||
      favorite != null;

  bool matches(CatalogCandidate candidate) {
    if (mediaTypes.isNotEmpty && !mediaTypes.contains(candidate.mediaType)) {
      return false;
    }
    if (!_matchesRange(
      candidate.runtimeMinutes,
      minimumRuntimeMinutes,
      maximumRuntimeMinutes,
    )) {
      return false;
    }
    if (!_matchesRange(
      candidate.communityRating,
      minimumCommunityRating,
      maximumCommunityRating,
    )) {
      return false;
    }
    if (!_matchesRange(
      candidate.criticRating,
      minimumCriticRating,
      maximumCriticRating,
    )) {
      return false;
    }
    final selectedGenres = genres.map((genre) => genre.toLowerCase()).toSet();
    if (selectedGenres.isNotEmpty &&
        candidate.genres
            .map((genre) => genre.toLowerCase())
            .toSet()
            .intersection(selectedGenres)
            .isEmpty) {
      return false;
    }
    if (decades.isNotEmpty) {
      final year = candidate.year;
      if (year == null || !decades.contains((year ~/ 10) * 10)) {
        return false;
      }
    }
    if (watched != null && candidate.watched != watched) {
      return false;
    }
    if (favorite != null && candidate.favorite != favorite) {
      return false;
    }
    return true;
  }

  bool _matchesRange<T extends num>(T? value, T? minimum, T? maximum) {
    if (minimum == null && maximum == null) {
      return true;
    }
    if (value == null) {
      return false;
    }
    return (minimum == null || value >= minimum) &&
        (maximum == null || value <= maximum);
  }
}
