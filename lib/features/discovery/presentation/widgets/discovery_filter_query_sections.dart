import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
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
          DropdownButtonFormField<String?>(
            key: WidgetKeys.discoveryLibraryField,
            isExpanded: true,
            initialValue: data.libraryId,
            decoration: InputDecoration(labelText: l10n.discoveryLibraryLabel),
            items: <DropdownMenuItem<String?>>[
              DropdownMenuItem<String?>(
                child: Text(l10n.discoveryAllLibrariesLabel),
              ),
              ...data.libraries.map(
                (library) => DropdownMenuItem<String?>(
                  value: library.id,
                  child: Text(library.name),
                ),
              ),
            ],
            onChanged: data.onLibraryChanged,
          ),
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
        CatalogSort.random => l10n.discoverySortRandomLabel,
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
