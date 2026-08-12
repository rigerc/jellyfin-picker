import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_filter.dart';

abstract final class CatalogFilterCodec {
  static Map<String, Object?> encode(CatalogFilter filter) => <String, Object?>{
    'mediaTypes': filter.mediaTypes.map((type) => type.name).toList()..sort(),
    'searchTerm': filter.searchTerm,
    'addedWithin': filter.addedWithin?.name,
    'sort': filter.sort.name,
    'minimumRuntimeMinutes': filter.minimumRuntimeMinutes,
    'maximumRuntimeMinutes': filter.maximumRuntimeMinutes,
    'minimumCommunityRating': filter.minimumCommunityRating,
    'maximumCommunityRating': filter.maximumCommunityRating,
    'minimumCriticRating': filter.minimumCriticRating,
    'maximumCriticRating': filter.maximumCriticRating,
    'genres': filter.genres.toList()..sort(),
    'decades': filter.decades.toList()..sort(),
    'officialRatings': filter.officialRatings.toList()..sort(),
    'seriesStatuses':
        filter.seriesStatuses.map((status) => status.name).toList()..sort(),
    'watched': filter.watched,
    'favorite': filter.favorite,
  };

  static CatalogFilter? decode(Object? value) {
    if (value is! Map) {
      return null;
    }
    final mediaTypes = _mediaTypes(value['mediaTypes']);
    final genres = _strings(value['genres']);
    final decades = _integers(value['decades']);
    final searchTerm = value.containsKey('searchTerm')
        ? _string(value['searchTerm'])
        : '';
    final addedWithin = _addedWithin(value['addedWithin']);
    final sort = _sort(value['sort']);
    final officialRatings = value.containsKey('officialRatings')
        ? _strings(value['officialRatings'])
        : <String>{};
    final seriesStatuses = value.containsKey('seriesStatuses')
        ? _seriesStatuses(value['seriesStatuses'])
        : <CatalogSeriesStatus>{};
    if (mediaTypes == null ||
        genres == null ||
        decades == null ||
        searchTerm == null ||
        officialRatings == null ||
        seriesStatuses == null ||
        (value.containsKey('addedWithin') &&
            value['addedWithin'] != null &&
            addedWithin == null) ||
        (value.containsKey('sort') && value['sort'] != null && sort == null)) {
      return null;
    }
    final minimumRuntime = _int(value['minimumRuntimeMinutes']);
    final maximumRuntime = _int(value['maximumRuntimeMinutes']);
    final minimumCommunity = _double(value['minimumCommunityRating']);
    final maximumCommunity = _double(value['maximumCommunityRating']);
    final minimumCritic = _double(value['minimumCriticRating']);
    final maximumCritic = _double(value['maximumCriticRating']);
    if (!_isNumberOrNull(value['minimumRuntimeMinutes'], minimumRuntime) ||
        !_isNumberOrNull(value['maximumRuntimeMinutes'], maximumRuntime) ||
        !_isNumberOrNull(value['minimumCommunityRating'], minimumCommunity) ||
        !_isNumberOrNull(value['maximumCommunityRating'], maximumCommunity) ||
        !_isNumberOrNull(value['minimumCriticRating'], minimumCritic) ||
        !_isNumberOrNull(value['maximumCriticRating'], maximumCritic) ||
        !_isBoolOrNull(value['watched']) ||
        !_isBoolOrNull(value['favorite'])) {
      return null;
    }
    if (!_isValidRange(minimumRuntime, maximumRuntime, 0) ||
        !_isValidRange(minimumCommunity, maximumCommunity, 0, 10) ||
        !_isValidRange(minimumCritic, maximumCritic, 0, 100) ||
        decades.any((decade) => decade < 0 || decade % 10 != 0) ||
        genres.any((genre) => genre.trim().isEmpty) ||
        officialRatings.any((rating) => rating.trim().isEmpty)) {
      return null;
    }
    return CatalogFilter(
      mediaTypes: mediaTypes,
      searchTerm: searchTerm,
      addedWithin: addedWithin,
      sort: sort ?? CatalogSort.defaultOrder,
      minimumRuntimeMinutes: minimumRuntime,
      maximumRuntimeMinutes: maximumRuntime,
      minimumCommunityRating: minimumCommunity,
      maximumCommunityRating: maximumCommunity,
      minimumCriticRating: minimumCritic,
      maximumCriticRating: maximumCritic,
      genres: genres,
      decades: decades,
      officialRatings: officialRatings,
      seriesStatuses: seriesStatuses,
      watched: value['watched'] as bool?,
      favorite: value['favorite'] as bool?,
    );
  }

  static Set<CatalogMediaType>? _mediaTypes(Object? value) {
    if (value is! List) {
      return null;
    }
    final result = <CatalogMediaType>{};
    for (final item in value) {
      final type = switch (item) {
        'movie' => CatalogMediaType.movie,
        'series' => CatalogMediaType.series,
        _ => null,
      };
      if (type == null) {
        return null;
      }
      result.add(type);
    }
    return result;
  }

  static Set<String>? _strings(Object? value) =>
      value is List && value.every((item) => item is String)
      ? value.whereType<String>().toSet()
      : null;

  static String? _string(Object? value) => value is String ? value : null;

  static CatalogAddedWindow? _addedWithin(Object? value) => switch (value) {
    'sevenDays' || 'days7' => CatalogAddedWindow.sevenDays,
    'thirtyDays' || 'days30' => CatalogAddedWindow.thirtyDays,
    'ninetyDays' || 'days90' => CatalogAddedWindow.ninetyDays,
    'threeHundredSixtyFiveDays' ||
    'days365' => CatalogAddedWindow.threeHundredSixtyFiveDays,
    _ => null,
  };

  static CatalogSort? _sort(Object? value) => switch (value) {
    'defaultOrder' => CatalogSort.defaultOrder,
    'recentlyAdded' => CatalogSort.recentlyAdded,
    'title' => CatalogSort.title,
    'releaseYear' => CatalogSort.releaseYear,
    'communityRating' => CatalogSort.communityRating,
    'runtime' => CatalogSort.runtime,
    null => CatalogSort.defaultOrder,
    _ => null,
  };

  static Set<CatalogSeriesStatus>? _seriesStatuses(Object? value) {
    if (value is! List) {
      return null;
    }
    final result = <CatalogSeriesStatus>{};
    for (final item in value) {
      final status = switch (item) {
        'continuing' => CatalogSeriesStatus.continuing,
        'ended' => CatalogSeriesStatus.ended,
        _ => null,
      };
      if (status == null) {
        return null;
      }
      result.add(status);
    }
    return result;
  }

  static Set<int>? _integers(Object? value) =>
      value is List && value.every((item) => item is int)
      ? value.whereType<int>().toSet()
      : null;

  static int? _int(Object? value) => value is int ? value : null;

  static double? _double(Object? value) =>
      value is num ? value.toDouble() : null;

  static bool _isNumberOrNull(Object? raw, Object? parsed) =>
      raw == null || parsed != null;

  static bool _isBoolOrNull(Object? value) => value == null || value is bool;

  static bool _isValidRange<T extends num>(
    T? minimum,
    T? maximum,
    num lowerBound, [
    num? upperBound,
  ]) {
    if (minimum != null && minimum < lowerBound) {
      return false;
    }
    if (maximum != null && maximum < lowerBound) {
      return false;
    }
    if (upperBound != null &&
        ((minimum != null && minimum > upperBound) ||
            (maximum != null && maximum > upperBound))) {
      return false;
    }
    return minimum == null || maximum == null || minimum <= maximum;
  }
}
