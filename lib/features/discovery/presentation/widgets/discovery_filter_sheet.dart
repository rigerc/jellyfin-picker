import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_filter.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

Future<void> showDiscoveryFilters(BuildContext context, CatalogFilter filter) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: context.read<DiscoveryCubit>(),
        child: DiscoveryFilterSheet(filter: filter),
      ),
    );

enum _TriState { any, yes, no }

final class DiscoveryFilterSheet extends StatefulWidget {
  const DiscoveryFilterSheet({required this.filter, super.key});

  final CatalogFilter filter;

  @override
  State<DiscoveryFilterSheet> createState() => _DiscoveryFilterSheetState();
}

final class _DiscoveryFilterSheetState extends State<DiscoveryFilterSheet> {
  static const _maximumRuntime = 300.0;
  static const _maximumCommunity = 10.0;
  static const _maximumCritic = 100.0;
  static const _decades = <int>[1970, 1980, 1990, 2000, 2010, 2020];

  late final TextEditingController _genresController;
  late final TextEditingController _presetController;
  late final Set<CatalogMediaType> _mediaTypes;
  late RangeValues _runtime;
  late double _community;
  late double _critic;
  late int? _decade;
  late _TriState _watched;
  late _TriState _favorite;

  @override
  void initState() {
    super.initState();
    final filter = widget.filter;
    _genresController = TextEditingController(text: filter.genres.join(', '));
    _presetController = TextEditingController();
    _mediaTypes = filter.mediaTypes.toSet();
    _runtime = RangeValues(
      (filter.minimumRuntimeMinutes ?? 0).toDouble(),
      (filter.maximumRuntimeMinutes ?? _maximumRuntime.toInt()).toDouble(),
    );
    _community = filter.minimumCommunityRating ?? 0;
    _critic = filter.minimumCriticRating ?? 0;
    _decade = filter.decades.firstOrNull;
    _watched = _fromBool(filter.watched);
    _favorite = _fromBool(filter.favorite);
  }

  @override
  void dispose() {
    _genresController.dispose();
    _presetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final presets = context.watch<DiscoveryCubit>().state.presets;
    return SafeArea(
      child: ListView(
        key: WidgetKeys.discoveryFilterSheet,
        padding: EdgeInsets.fromLTRB(
          CandySpacing.page,
          CandySpacing.compact,
          CandySpacing.page,
          CandySpacing.page + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: <Widget>[
          Text(
            localization.discoveryFilterSheetTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: CandySpacing.cardGap),
          _FilterSection(
            title: localization.discoveryMediaTypeLabel,
            icon: Icons.local_movies_outlined,
            child: Wrap(
              spacing: CandySpacing.compact,
              runSpacing: CandySpacing.compact,
              children: <Widget>[
                FilterChip(
                  key: WidgetKeys.discoveryMovieFilter,
                  label: Text(localization.discoveryMoviesLabel),
                  selected: _mediaTypes.contains(CatalogMediaType.movie),
                  onSelected: (selected) =>
                      _toggleType(CatalogMediaType.movie, selected),
                ),
                FilterChip(
                  key: WidgetKeys.discoverySeriesFilter,
                  label: Text(localization.discoverySeriesLabel),
                  selected: _mediaTypes.contains(CatalogMediaType.series),
                  onSelected: (selected) =>
                      _toggleType(CatalogMediaType.series, selected),
                ),
              ],
            ),
          ),
          const SizedBox(height: CandySpacing.cardGap),
          _FilterSection(
            title: localization.discoveryFineTuneFiltersLabel,
            icon: Icons.tune_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: CandySpacing.compact,
              children: <Widget>[
                Text(
                  localization.discoveryRuntimeFilterLabel(
                    _runtime.start.round(),
                    _runtime.end.round(),
                  ),
                ),
                RangeSlider(
                  values: _runtime,
                  max: _maximumRuntime,
                  onChanged: (value) => setState(() => _runtime = value),
                ),
                Text(
                  localization.discoveryCommunityFilterLabel(
                    _community.toStringAsFixed(1),
                  ),
                ),
                Slider(
                  value: _community,
                  max: _maximumCommunity,
                  onChanged: (value) => setState(() => _community = value),
                ),
                Text(
                  localization.discoveryCriticFilterLabel(
                    _critic.toStringAsFixed(0),
                  ),
                ),
                Slider(
                  value: _critic,
                  max: _maximumCritic,
                  onChanged: (value) => setState(() => _critic = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: CandySpacing.cardGap),
          _FilterSection(
            title: localization.discoveryLibraryDetailsLabel,
            icon: Icons.category_outlined,
            child: Column(
              spacing: CandySpacing.cardGap,
              children: <Widget>[
                TextField(
                  controller: _genresController,
                  decoration: InputDecoration(
                    labelText: localization.discoveryGenresFilterLabel,
                  ),
                ),
                _DecadeField(
                  value: _decade,
                  decades: _decades,
                  onChanged: (value) => setState(() => _decade = value),
                ),
                _TriStateField(
                  label: localization.discoveryWatchedFilterLabel,
                  value: _watched,
                  onChanged: (value) => setState(() => _watched = value),
                ),
                _TriStateField(
                  label: localization.discoveryFavoriteFilterLabel,
                  value: _favorite,
                  onChanged: (value) => setState(() => _favorite = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: CandySpacing.cardGap),
          _FilterSection(
            title: localization.discoveryPresetsLabel,
            icon: Icons.bookmarks_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: CandySpacing.compact,
              children: <Widget>[
                if (presets.isNotEmpty)
                  Wrap(
                    spacing: CandySpacing.compact,
                    runSpacing: CandySpacing.compact,
                    children: presets.keys
                        .map(
                          (name) => ActionChip(
                            label: Text(name),
                            onPressed: () => _applyPreset(name),
                          ),
                        )
                        .toList(growable: false),
                  ),
                TextField(
                  key: WidgetKeys.discoveryPresetName,
                  controller: _presetController,
                  maxLength: 50,
                  decoration: InputDecoration(
                    labelText: localization.discoveryPresetNameLabel,
                  ),
                ),
                OutlinedButton.icon(
                  key: WidgetKeys.discoverySavePreset,
                  onPressed: _savePreset,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: Text(localization.discoverySavePresetLabel),
                ),
              ],
            ),
          ),
          const SizedBox(height: CandySpacing.cardGap),
          FilledButton(
            key: WidgetKeys.discoveryApplyFilters,
            onPressed: _apply,
            child: Text(localization.discoveryApplyFiltersLabel),
          ),
        ],
      ),
    );
  }

  void _toggleType(CatalogMediaType type, bool selected) {
    setState(() => selected ? _mediaTypes.add(type) : _mediaTypes.remove(type));
  }

  Future<void> _apply() async {
    final genres = _genresController.text
        .split(',')
        .map((genre) => genre.trim().toLowerCase())
        .where((genre) => genre.isNotEmpty)
        .toSet();
    await context.read<DiscoveryCubit>().updateFilter(
      CatalogFilter(
        mediaTypes: _mediaTypes,
        minimumRuntimeMinutes: _runtime.start == 0
            ? null
            : _runtime.start.round(),
        maximumRuntimeMinutes: _runtime.end == _maximumRuntime
            ? null
            : _runtime.end.round(),
        minimumCommunityRating: _community == 0 ? null : _community,
        minimumCriticRating: _critic == 0 ? null : _critic,
        genres: genres,
        decades: switch (_decade) {
          final decade? => <int>{decade},
          null => const <int>{},
        },
        watched: _toBool(_watched),
        favorite: _toBool(_favorite),
      ),
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _savePreset() async {
    final name = _presetController.text.trim();
    if (name.isEmpty) {
      return;
    }
    await context.read<DiscoveryCubit>().savePreset(name);
    _presetController.clear();
  }

  Future<void> _applyPreset(String name) async {
    await context.read<DiscoveryCubit>().applyPreset(name);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  static _TriState _fromBool(bool? value) => switch (value) {
    true => _TriState.yes,
    false => _TriState.no,
    null => _TriState.any,
  };

  static bool? _toBool(_TriState value) => switch (value) {
    _TriState.any => null,
    _TriState.yes => true,
    _TriState.no => false,
  };
}

final class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(CandySpacing.cardGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CandySpacing.compact,
        children: <Widget>[
          Row(
            spacing: CandySpacing.compact,
            children: <Widget>[
              Icon(icon),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    ),
  );
}

final class _DecadeField extends StatelessWidget {
  const _DecadeField({
    required this.value,
    required this.decades,
    required this.onChanged,
  });

  final int? value;
  final List<int> decades;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return DropdownButtonFormField<int?>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: localization.discoveryDecadeFilterLabel,
      ),
      items: <DropdownMenuItem<int?>>[
        DropdownMenuItem<int?>(child: Text(localization.discoveryAnyLabel)),
        ...decades.map(
          (decade) =>
              DropdownMenuItem<int?>(value: decade, child: Text('${decade}s')),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

final class _TriStateField extends StatelessWidget {
  const _TriStateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final _TriState value;
  final ValueChanged<_TriState> onChanged;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return DropdownButtonFormField<_TriState>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: <DropdownMenuItem<_TriState>>[
        DropdownMenuItem<_TriState>(
          value: _TriState.any,
          child: Text(localization.discoveryAnyLabel),
        ),
        DropdownMenuItem<_TriState>(
          value: _TriState.yes,
          child: Text(localization.discoveryYesLabel),
        ),
        DropdownMenuItem<_TriState>(
          value: _TriState.no,
          child: Text(localization.discoveryNoLabel),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
