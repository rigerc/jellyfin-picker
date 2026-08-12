import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_form.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_sections.dart';

final class DiscoveryFilterSheet extends StatefulWidget {
  const DiscoveryFilterSheet({
    required this.filter,
    this.candidates = const <CatalogCandidate>[],
    super.key,
  });

  final CatalogFilter filter;
  final Iterable<CatalogCandidate> candidates;

  @override
  State<DiscoveryFilterSheet> createState() => _DiscoveryFilterSheetState();
}

final class _DiscoveryFilterSheetState extends State<DiscoveryFilterSheet> {
  static const _maxRuntime = 300.0;
  final _search = TextEditingController();
  final _genresText = TextEditingController();
  final _presetText = TextEditingController();
  late Set<CatalogMediaType> _mediaTypes;
  late Set<String> _genres;
  late Set<int> _decades;
  late Set<String> _ratings;
  late Set<CatalogSeriesStatus> _statuses;
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
    _mediaTypes = filter.mediaTypes.toSet();
    _genres = filter.genres.toSet();
    _decades = filter.decades.toSet();
    _ratings = filter.officialRatings.toSet();
    _statuses = filter.seriesStatuses.toSet();
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
      query: (
        searchController: _search,
        sort: _sort,
        addedWithin: _addedWithin,
        onSortChanged: (value) => setState(() => _sort = value),
        onAddedWithinChanged: (value) => setState(() => _addedWithin = value),
      ),
      mediaTypes: (selected: _mediaTypes, onChanged: _toggleMediaType),
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
        seriesStatuses: _statuses,
        watched: _watched,
        favorite: _favorite,
        availableGenres: _genresFromCandidates,
        availableDecades: _decadesFromCandidates,
        availableRatings: _ratingsFromCandidates,
        availableStatuses: _statusesFromCandidates,
        onGenreChanged: _toggleGenre,
        onDecadeChanged: _toggleDecade,
        onOfficialRatingChanged: _toggleRating,
        onSeriesStatusChanged: _toggleStatus,
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
      _candidateList
          .expand((candidate) => candidate.genres)
          .followedBy(_genres)
          .toSet()
          .toList()
        ..sort();

  List<int> get _decadesFromCandidates =>
      _candidateList
          .map((candidate) => candidate.year)
          .whereType<int>()
          .map((year) => (year ~/ 10) * 10)
          .followedBy(_decades)
          .toSet()
          .toList()
        ..sort();

  List<String> get _ratingsFromCandidates =>
      _candidateList
          .map((candidate) => candidate.officialRating)
          .whereType<String>()
          .followedBy(_ratings)
          .toSet()
          .toList()
        ..sort();

  List<CatalogSeriesStatus> get _statusesFromCandidates => CatalogSeriesStatus
      .values
      .where(
        (status) =>
            _statuses.contains(status) ||
            _candidateList.any(
              (candidate) => _matchesStatus(status, candidate.status),
            ),
      )
      .toList(growable: false);

  void _toggleMediaType(CatalogMediaType type, bool selected) => setState(
    () => selected ? _mediaTypes.add(type) : _mediaTypes.remove(type),
  );

  void _toggleGenre(String genre, bool selected) =>
      setState(() => selected ? _genres.add(genre) : _genres.remove(genre));

  void _toggleDecade(int decade, bool selected) =>
      setState(() => selected ? _decades.add(decade) : _decades.remove(decade));

  void _toggleRating(String rating, bool selected) =>
      setState(() => selected ? _ratings.add(rating) : _ratings.remove(rating));

  void _toggleStatus(CatalogSeriesStatus status, bool selected) => setState(
    () => selected ? _statuses.add(status) : _statuses.remove(status),
  );

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
        searchTerm: _search.text.trim(),
        addedWithin: _addedWithin,
        sort: _sort,
        mediaTypes: _mediaTypes,
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
        seriesStatuses: _statuses,
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

  static bool _matchesStatus(CatalogSeriesStatus status, String? value) {
    final normalized = value?.toLowerCase() ?? '';
    return status == CatalogSeriesStatus.continuing
        ? normalized.contains('returning') || normalized.contains('continuing')
        : normalized.contains('ended') || normalized.contains('cancel');
  }
}
