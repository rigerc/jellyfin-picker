import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';

enum CatalogAddedWindow {
  sevenDays,
  thirtyDays,
  ninetyDays,
  threeHundredSixtyFiveDays;

  int get days => switch (this) {
    CatalogAddedWindow.sevenDays => 7,
    CatalogAddedWindow.thirtyDays => 30,
    CatalogAddedWindow.ninetyDays => 90,
    CatalogAddedWindow.threeHundredSixtyFiveDays => 365,
  };
}

enum CatalogSort {
  defaultOrder,
  random,
  recentlyAdded,
  title,
  releaseYear,
  communityRating,
  runtime,
}

enum CatalogSeriesStatus { continuing, ended }

/// Filter dimensions are ANDed; multi-valued attributes require every value.
final class CatalogFilter {
  const CatalogFilter({
    Set<CatalogMediaType> mediaTypes = const <CatalogMediaType>{},
    this.libraryId,
    this.searchTerm = '',
    this.addedWithin,
    this.dateWindowAnchor,
    this.sort = CatalogSort.defaultOrder,
    this.minimumRuntimeMinutes,
    this.maximumRuntimeMinutes,
    this.minimumCommunityRating,
    this.maximumCommunityRating,
    this.minimumCriticRating,
    this.maximumCriticRating,
    Set<String> genres = const <String>{},
    Set<int> decades = const <int>{},
    Set<String> officialRatings = const <String>{},
    Set<CatalogSeriesStatus> seriesStatuses = const <CatalogSeriesStatus>{},
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
       _decades = decades,
       // Public constructor names intentionally differ from backing fields.
       // ignore: prefer_initializing_formals
       _officialRatings = officialRatings,
       // Public constructor names intentionally differ from backing fields.
       // ignore: prefer_initializing_formals
       _seriesStatuses = seriesStatuses;

  final Set<CatalogMediaType> _mediaTypes;
  final String? libraryId;
  final String searchTerm;
  final CatalogAddedWindow? addedWithin;
  final DateTime? dateWindowAnchor;
  final CatalogSort sort;
  final int? minimumRuntimeMinutes;
  final int? maximumRuntimeMinutes;
  final double? minimumCommunityRating;
  final double? maximumCommunityRating;
  final double? minimumCriticRating;
  final double? maximumCriticRating;
  final Set<String> _genres;
  final Set<int> _decades;
  final Set<String> _officialRatings;
  final Set<CatalogSeriesStatus> _seriesStatuses;
  final bool? watched;
  final bool? favorite;

  Set<CatalogMediaType> get mediaTypes =>
      Set<CatalogMediaType>.unmodifiable(_mediaTypes);

  Set<String> get genres => Set<String>.unmodifiable(_genres);

  Set<int> get decades => Set<int>.unmodifiable(_decades);

  Set<String> get officialRatings => Set<String>.unmodifiable(_officialRatings);

  Set<CatalogSeriesStatus> get seriesStatuses =>
      Set<CatalogSeriesStatus>.unmodifiable(_seriesStatuses);

  bool get isActive =>
      libraryId != null ||
      mediaTypes.isNotEmpty ||
      searchTerm.trim().isNotEmpty ||
      addedWithin != null ||
      minimumRuntimeMinutes != null ||
      maximumRuntimeMinutes != null ||
      minimumCommunityRating != null ||
      maximumCommunityRating != null ||
      minimumCriticRating != null ||
      maximumCriticRating != null ||
      genres.isNotEmpty ||
      decades.isNotEmpty ||
      _hasOfficialRatingConstraint ||
      seriesStatuses.isNotEmpty ||
      watched != null ||
      favorite != null;

  bool matches(CatalogCandidate candidate, {DateTime? now}) =>
      _matchesMediaType(candidate) &&
      _matchesSearch(candidate) &&
      _matchesAddedWithin(candidate, now) &&
      _matchesNumericRanges(candidate) &&
      _matchesGenres(candidate) &&
      _matchesDecades(candidate) &&
      _matchesOfficialRating(candidate) &&
      _matchesSeries(candidate) &&
      _matchesFlags(candidate);

  bool _matchesMediaType(CatalogCandidate candidate) =>
      candidate.mediaType == CatalogMediaType.movie &&
      (mediaTypes.isEmpty || mediaTypes.contains(CatalogMediaType.movie));

  bool _matchesSearch(CatalogCandidate candidate) {
    final normalizedSearchTerm = _normalize(searchTerm);
    return normalizedSearchTerm.isEmpty ||
        _normalize(candidate.name).contains(normalizedSearchTerm);
  }

  bool _matchesAddedWithin(CatalogCandidate candidate, DateTime? now) {
    final window = addedWithin;
    if (window == null) {
      return true;
    }
    final dateCreated = candidate.dateCreated;
    if (dateCreated == null) {
      return false;
    }
    final currentTime = (now ?? dateWindowAnchor ?? DateTime.now()).toUtc();
    final cutoff = currentTime.subtract(Duration(days: window.days));
    final normalizedDateCreated = dateCreated.toUtc();
    return normalizedDateCreated.isAfter(cutoff) ||
        normalizedDateCreated.isAtSameMomentAs(cutoff);
  }

  bool _matchesNumericRanges(CatalogCandidate candidate) =>
      _matchesRange(
        candidate.runtimeMinutes,
        minimumRuntimeMinutes,
        maximumRuntimeMinutes,
      ) &&
      _matchesRange(
        candidate.communityRating,
        minimumCommunityRating,
        maximumCommunityRating,
      ) &&
      _matchesRange(
        candidate.criticRating,
        minimumCriticRating,
        maximumCriticRating,
      );

  bool _matchesGenres(CatalogCandidate candidate) {
    final selectedGenres = genres.map((genre) => genre.toLowerCase()).toSet();
    if (selectedGenres.isEmpty) {
      return true;
    }
    final candidateGenres = candidate.genres
        .map((genre) => genre.toLowerCase())
        .toSet();
    return candidateGenres.containsAll(selectedGenres);
  }

  bool _matchesDecades(CatalogCandidate candidate) {
    if (decades.isEmpty) {
      return true;
    }
    final year = candidate.year;
    return year != null && decades.contains((year ~/ 10) * 10);
  }

  bool _matchesOfficialRating(CatalogCandidate candidate) {
    final selectedOfficialRatings = _normalizedOfficialRatings;
    if (selectedOfficialRatings.isEmpty) {
      return true;
    }
    final officialRating = candidate.officialRating;
    return officialRating != null &&
        selectedOfficialRatings.contains(_normalize(officialRating));
  }

  bool _matchesSeries(CatalogCandidate candidate) {
    if (seriesStatuses.isEmpty) {
      return true;
    }
    final status = candidate.status;
    return status != null && _matchesSeriesStatus(status);
  }

  bool _matchesFlags(CatalogCandidate candidate) =>
      (watched == null || candidate.watched == watched) &&
      (favorite == null || candidate.favorite == favorite);

  CatalogFilter copyWith({
    Set<CatalogMediaType>? mediaTypes,
    Object? libraryId = _unset,
    String? searchTerm,
    Object? addedWithin = _unset,
    Object? dateWindowAnchor = _unset,
    CatalogSort? sort,
    Object? minimumRuntimeMinutes = _unset,
    Object? maximumRuntimeMinutes = _unset,
    Object? minimumCommunityRating = _unset,
    Object? maximumCommunityRating = _unset,
    Object? minimumCriticRating = _unset,
    Object? maximumCriticRating = _unset,
    Set<String>? genres,
    Set<int>? decades,
    Set<String>? officialRatings,
    Set<CatalogSeriesStatus>? seriesStatuses,
    Object? watched = _unset,
    Object? favorite = _unset,
  }) => CatalogFilter(
    mediaTypes: mediaTypes ?? this.mediaTypes,
    libraryId: _copyString(libraryId, this.libraryId),
    searchTerm: searchTerm ?? this.searchTerm,
    addedWithin: _copyWindow(addedWithin, this.addedWithin),
    dateWindowAnchor: _copyDate(dateWindowAnchor, this.dateWindowAnchor),
    sort: sort ?? this.sort,
    minimumRuntimeMinutes: _copyInt(
      minimumRuntimeMinutes,
      this.minimumRuntimeMinutes,
    ),
    maximumRuntimeMinutes: _copyInt(
      maximumRuntimeMinutes,
      this.maximumRuntimeMinutes,
    ),
    minimumCommunityRating: _copyDouble(
      minimumCommunityRating,
      this.minimumCommunityRating,
    ),
    maximumCommunityRating: _copyDouble(
      maximumCommunityRating,
      this.maximumCommunityRating,
    ),
    minimumCriticRating: _copyDouble(
      minimumCriticRating,
      this.minimumCriticRating,
    ),
    maximumCriticRating: _copyDouble(
      maximumCriticRating,
      this.maximumCriticRating,
    ),
    genres: genres ?? this.genres,
    decades: decades ?? this.decades,
    officialRatings: officialRatings ?? this.officialRatings,
    seriesStatuses: seriesStatuses ?? this.seriesStatuses,
    watched: _copyBool(watched, this.watched),
    favorite: _copyBool(favorite, this.favorite),
  );

  static CatalogAddedWindow? _copyWindow(
    Object? value,
    CatalogAddedWindow? current,
  ) => identical(value, _unset)
      ? current
      : value is CatalogAddedWindow
      ? value
      : null;

  static int? _copyInt(Object? value, int? current) => identical(value, _unset)
      ? current
      : value is int
      ? value
      : null;

  static DateTime? _copyDate(Object? value, DateTime? current) =>
      identical(value, _unset)
      ? current
      : value is DateTime
      ? value
      : null;

  static double? _copyDouble(Object? value, double? current) =>
      identical(value, _unset)
      ? current
      : value is num
      ? value.toDouble()
      : null;

  static bool? _copyBool(Object? value, bool? current) =>
      identical(value, _unset)
      ? current
      : value is bool
      ? value
      : null;

  static String? _copyString(Object? value, String? current) =>
      identical(value, _unset)
      ? current
      : value is String && value.trim().isNotEmpty
      ? value.trim()
      : null;

  bool get _hasOfficialRatingConstraint =>
      _normalizedOfficialRatings.isNotEmpty;

  Set<String> get _normalizedOfficialRatings => _officialRatings
      .map(_normalize)
      .where((rating) => rating.isNotEmpty)
      .toSet();

  bool _matchesSeriesStatus(String status) {
    final normalizedStatus = _normalize(status);
    return seriesStatuses.any(
      (selectedStatus) => switch (selectedStatus) {
        CatalogSeriesStatus.continuing => _continuingStatuses.contains(
          normalizedStatus,
        ),
        CatalogSeriesStatus.ended => _endedStatuses.contains(normalizedStatus),
      },
    );
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static const _continuingStatuses = <String>{
    'continuing',
    'returning series',
    'in production',
  };

  static const _endedStatuses = <String>{'ended', 'canceled', 'cancelled'};

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

const _unset = Object();
