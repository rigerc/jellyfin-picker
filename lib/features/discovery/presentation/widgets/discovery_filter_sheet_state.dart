import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_facets.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_library.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_form.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_sections.dart';

final class DiscoveryFilterSheet extends StatefulWidget {
  const DiscoveryFilterSheet({
    required this.filter,
    this.candidates = const <CatalogCandidate>[],
    this.libraries = const <CatalogLibrary>[],
    this.facets = const CatalogFacets(),
    super.key,
  });

  final CatalogFilter filter;
  final Iterable<CatalogCandidate> candidates;
  final List<CatalogLibrary> libraries;
  final CatalogFacets facets;

  @override
  State<DiscoveryFilterSheet> createState() => _DiscoveryFilterSheetState();
}

final class _DiscoveryFilterSheetState extends State<DiscoveryFilterSheet> {
  static const _maxRuntime = 300.0;
  final _search = TextEditingController();
  final _genresText = TextEditingController();
  final _presetText = TextEditingController();
  late String? _libraryId;
  late Set<String> _genres;
  late Set<int> _decades;
  late Set<String> _ratings;
  late RangeValues _runtime;
  late double _community;
  late double _critic;
  late DiscoveryTriState _watched;
  late DiscoveryTriState _favorite;
  late CatalogSort _sort;
  late CatalogAddedWindow? _addedWithin;
  late final List<CatalogCandidate> _candidateList;

  @override
  void initState() {
    super.initState();
    final filter = widget.filter;
    _candidateList = List<CatalogCandidate>.unmodifiable(widget.candidates);
    _search.text = filter.searchTerm;
    _genresText.text = filter.genres.join(', ');
    _libraryId =
        widget.libraries.any((library) => library.id == filter.libraryId)
        ? filter.libraryId
        : null;
    _genres = filter.genres.toSet();
    _decades = filter.decades.toSet();
    _ratings = filter.officialRatings.toSet();
    _runtime = RangeValues(
      (filter.minimumRuntimeMinutes ?? 0).toDouble(),
      (filter.maximumRuntimeMinutes ?? _maxRuntime).toDouble(),
    );
    _community = filter.minimumCommunityRating ?? 0;
    _critic = filter.minimumCriticRating ?? 0;
    _watched = _triState(filter.watched);
    _favorite = _triState(filter.favorite);
    _sort = filter.sort;
    _addedWithin = filter.addedWithin;
  }

  @override
  void dispose() {
    _search.dispose();
    _genresText.dispose();
    _presetText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DiscoveryCubit>().state;
    return DiscoveryFilterBody(
      quickFilters: (
        recent: _addedWithin == CatalogAddedWindow.thirtyDays,
        unwatched: _watched == DiscoveryTriState.no,
        favorites: _favorite == DiscoveryTriState.yes,
        onRecentChanged: (selected) => setState(
          () => _addedWithin = selected ? CatalogAddedWindow.thirtyDays : null,
        ),
        onUnwatchedChanged: (selected) => setState(
          () => _watched = selected
              ? DiscoveryTriState.no
              : DiscoveryTriState.any,
        ),
        onFavoritesChanged: (selected) => setState(
          () => _favorite = selected
              ? DiscoveryTriState.yes
              : DiscoveryTriState.any,
        ),
      ),
      query: (
        searchController: _search,
        libraries: widget.libraries,
        libraryId: _libraryId,
        sort: _sort,
        addedWithin: _addedWithin,
        onSortChanged: (value) => setState(() => _sort = value),
        onLibraryChanged: (value) => setState(() => _libraryId = value),
        onAddedWithinChanged: (value) => setState(() => _addedWithin = value),
      ),
      ratings: (
        runtime: _runtime,
        community: _community,
        critic: _critic,
        onRuntimeChanged: (value) => setState(() => _runtime = value),
        onCommunityChanged: (value) => setState(() => _community = value),
        onCriticChanged: (value) => setState(() => _critic = value),
      ),
      metadata: (
        genresController: _genresText,
        genres: _genres,
        decades: _decades,
        officialRatings: _ratings,
        watched: _watched,
        favorite: _favorite,
        availableGenres: _genresFromCandidates,
        availableDecades: _decadesFromCandidates,
        availableRatings: _ratingsFromCandidates,
        onGenreChanged: _toggleGenre,
        onDecadeChanged: _toggleDecade,
        onOfficialRatingChanged: _toggleRating,
        onWatchedChanged: (value) => setState(() => _watched = value),
        onFavoriteChanged: (value) => setState(() => _favorite = value),
      ),
      presets: (
        nameController: _presetText,
        presets: state.presets,
        onApply: _applyPreset,
        onSave: _savePreset,
      ),
      onReset: _reset,
      onApply: _apply,
    );
  }

  List<String> get _genresFromCandidates =>
      (widget.facets.genres.isEmpty
              ? _candidateList.expand((candidate) => candidate.genres)
              : widget.facets.genres)
          .followedBy(_genres)
          .toSet()
          .toList()
        ..sort();

  List<int> get _decadesFromCandidates =>
      (widget.facets.years.isEmpty
              ? _candidateList
                    .map((candidate) => candidate.year)
                    .whereType<int>()
              : widget.facets.years)
          .map((year) => (year ~/ 10) * 10)
          .followedBy(_decades)
          .toSet()
          .toList()
        ..sort();

  List<String> get _ratingsFromCandidates =>
      (widget.facets.officialRatings.isEmpty
              ? _candidateList
                    .map((candidate) => candidate.officialRating)
                    .whereType<String>()
              : widget.facets.officialRatings)
          .followedBy(_ratings)
          .toSet()
          .toList()
        ..sort();

  void _toggleGenre(String genre, bool selected) =>
      setState(() => selected ? _genres.add(genre) : _genres.remove(genre));

  void _toggleDecade(int decade, bool selected) =>
      setState(() => selected ? _decades.add(decade) : _decades.remove(decade));

  void _toggleRating(String rating, bool selected) =>
      setState(() => selected ? _ratings.add(rating) : _ratings.remove(rating));

  Future<void> _apply() async {
    final genres = _genres.isNotEmpty
        ? _genres
        : _genresText.text
              .split(',')
              .map((value) => value.trim().toLowerCase())
              .where((value) => value.isNotEmpty)
              .toSet();
    await context.read<DiscoveryCubit>().updateFilter(
      CatalogFilter(
        libraryId: _libraryId,
        searchTerm: _search.text.trim(),
        addedWithin: _addedWithin,
        sort: _sort,
        minimumRuntimeMinutes: _runtime.start == 0
            ? null
            : _runtime.start.round(),
        maximumRuntimeMinutes: _runtime.end == _maxRuntime
            ? null
            : _runtime.end.round(),
        minimumCommunityRating: _community == 0 ? null : _community,
        maximumCommunityRating: widget.filter.maximumCommunityRating,
        minimumCriticRating: _critic == 0 ? null : _critic,
        maximumCriticRating: widget.filter.maximumCriticRating,
        genres: genres,
        decades: _decades,
        officialRatings: _ratings,
        watched: _bool(_watched),
        favorite: _bool(_favorite),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _reset() async {
    await context.read<DiscoveryCubit>().resetFilters();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _savePreset() async {
    final name = _presetText.text.trim();
    if (name.isEmpty) return;
    await context.read<DiscoveryCubit>().savePreset(name);
    _presetText.clear();
  }

  Future<void> _applyPreset(String name) async {
    await context.read<DiscoveryCubit>().applyPreset(name);
    if (mounted) Navigator.pop(context);
  }

  static DiscoveryTriState _triState(bool? value) => switch (value) {
    true => DiscoveryTriState.yes,
    false => DiscoveryTriState.no,
    null => DiscoveryTriState.any,
  };

  static bool? _bool(DiscoveryTriState value) => switch (value) {
    DiscoveryTriState.any => null,
    DiscoveryTriState.yes => true,
    DiscoveryTriState.no => false,
  };
}
