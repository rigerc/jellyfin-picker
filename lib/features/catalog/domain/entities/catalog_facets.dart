final class CatalogFacetValue {
  const CatalogFacetValue({required this.name, required this.value});

  final String name;
  final String value;

  @override
  bool operator ==(Object other) =>
      other is CatalogFacetValue && other.name == name && other.value == value;

  @override
  int get hashCode => Object.hash(name, value);
}

final class CatalogFacets {
  const CatalogFacets({
    this.genres = const <String>[],
    this.years = const <int>[],
    this.officialRatings = const <String>[],
    this.tags = const <String>[],
    this.audioLanguages = const <CatalogFacetValue>[],
    this.subtitleLanguages = const <CatalogFacetValue>[],
  });

  final List<String> genres;
  final List<int> years;
  final List<String> officialRatings;
  final List<String> tags;
  final List<CatalogFacetValue> audioLanguages;
  final List<CatalogFacetValue> subtitleLanguages;

  @override
  bool operator ==(Object other) =>
      other is CatalogFacets &&
      _listEquals(other.genres, genres) &&
      _listEquals(other.years, years) &&
      _listEquals(other.officialRatings, officialRatings) &&
      _listEquals(other.tags, tags) &&
      _listEquals(other.audioLanguages, audioLanguages) &&
      _listEquals(other.subtitleLanguages, subtitleLanguages);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(genres),
    Object.hashAll(years),
    Object.hashAll(officialRatings),
    Object.hashAll(tags),
    Object.hashAll(audioLanguages),
    Object.hashAll(subtitleLanguages),
  );

  static bool _listEquals<T>(List<T> left, List<T> right) =>
      left.length == right.length &&
      left.asMap().entries.every((entry) => entry.value == right[entry.key]);
}
