import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_filter.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_models.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_sections.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

final class DiscoverySortFilterSection extends StatelessWidget {
  const DiscoverySortFilterSection({required this.data, super.key});

  final DiscoveryQueryFilterData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DiscoveryFilterSection(
      title: l10n.discoverySortLabel,
      icon: Icons.sort_rounded,
      child: Column(
        spacing: CandySpacing.compact,
        children: <Widget>[
          DropdownButtonFormField<CatalogSort>(
            key: WidgetKeys.discoverySortField,
            isExpanded: true,
            initialValue: data.sort,
            decoration: InputDecoration(labelText: l10n.discoverySortLabel),
            items: CatalogSort.values
                .map(
                  (value) => DropdownMenuItem<CatalogSort>(
                    value: value,
                    child: Text(_sortLabel(l10n, value)),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) data.onSortChanged(value);
            },
          ),
          DropdownButtonFormField<CatalogAddedWindow?>(
            key: WidgetKeys.discoveryAddedWithinField,
            initialValue: data.addedWithin,
            decoration: InputDecoration(
              labelText: l10n.discoveryAddedWithinLabel,
            ),
            items: <DropdownMenuItem<CatalogAddedWindow?>>[
              DropdownMenuItem<CatalogAddedWindow?>(
                child: Text(l10n.discoveryAddedWithinAnyLabel),
              ),
              ...CatalogAddedWindow.values.map(
                (value) => DropdownMenuItem<CatalogAddedWindow?>(
                  value: value,
                  child: Text(_windowLabel(l10n, value)),
                ),
              ),
            ],
            onChanged: data.onAddedWithinChanged,
          ),
        ],
      ),
    );
  }

  static String _sortLabel(AppLocalizations l10n, CatalogSort value) =>
      switch (value) {
        CatalogSort.defaultOrder => l10n.discoverySortDefaultLabel,
        CatalogSort.recentlyAdded => l10n.discoverySortRecentlyAddedLabel,
        CatalogSort.title => l10n.discoverySortTitleLabel,
        CatalogSort.releaseYear => l10n.discoverySortReleaseYearLabel,
        CatalogSort.communityRating => l10n.discoverySortCommunityRatingLabel,
        CatalogSort.runtime => l10n.discoverySortRuntimeLabel,
      };

  static String _windowLabel(AppLocalizations l10n, CatalogAddedWindow value) =>
      switch (value) {
        CatalogAddedWindow.sevenDays => l10n.discoveryAddedWithinWeekLabel,
        CatalogAddedWindow.thirtyDays => l10n.discoveryAddedWithinMonthLabel,
        CatalogAddedWindow.ninetyDays => l10n.discoveryAddedWithinQuarterLabel,
        CatalogAddedWindow.threeHundredSixtyFiveDays =>
          l10n.discoveryAddedWithinYearLabel,
      };
}

final class DiscoveryMediaTypeFilterSection extends StatelessWidget {
  const DiscoveryMediaTypeFilterSection({required this.data, super.key});

  final DiscoveryMediaTypeFilterData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DiscoveryFilterSection(
      title: l10n.discoveryMediaTypeLabel,
      icon: Icons.local_movies_outlined,
      child: Wrap(
        spacing: CandySpacing.compact,
        runSpacing: CandySpacing.compact,
        children: <Widget>[
          FilterChip(
            key: WidgetKeys.discoveryMovieFilter,
            label: Text(l10n.discoveryMoviesLabel),
            selected: data.selected.contains(CatalogMediaType.movie),
            onSelected: (selected) =>
                data.onChanged(CatalogMediaType.movie, selected),
          ),
          FilterChip(
            key: WidgetKeys.discoverySeriesFilter,
            label: Text(l10n.discoverySeriesLabel),
            selected: data.selected.contains(CatalogMediaType.series),
            onSelected: (selected) =>
                data.onChanged(CatalogMediaType.series, selected),
          ),
        ],
      ),
    );
  }
}
