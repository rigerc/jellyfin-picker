import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_metadata_section.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_models.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_preset_section.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_query_sections.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_rating_section.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

final class DiscoveryFilterBody extends StatelessWidget {
  const DiscoveryFilterBody({
    required this.query,
    required this.mediaTypes,
    required this.ratings,
    required this.metadata,
    required this.presets,
    required this.onReset,
    required this.onApply,
    super.key,
  });

  final DiscoveryQueryFilterData query;
  final DiscoveryMediaTypeFilterData mediaTypes;
  final DiscoveryRatingFilterData ratings;
  final DiscoveryMetadataFilterData metadata;
  final DiscoveryPresetFilterData presets;
  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        key: WidgetKeys.discoveryFilterSheet,
        padding: EdgeInsets.fromLTRB(
          CandySpacing.page,
          CandySpacing.compact,
          CandySpacing.page,
          CandySpacing.page + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: <Widget>[
            Text(
              l10n.discoveryFilterSheetTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            OutlinedButton.icon(
              key: WidgetKeys.discoveryResetFilters,
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(l10n.discoveryResetFiltersLabel),
            ),
            TextField(
              key: WidgetKeys.discoverySearchField,
              controller: query.searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: l10n.discoverySearchTitleLabel,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: CandySpacing.cardGap),
            DiscoverySortFilterSection(data: query),
            const SizedBox(height: CandySpacing.cardGap),
            DiscoveryMediaTypeFilterSection(data: mediaTypes),
            const SizedBox(height: CandySpacing.cardGap),
            DiscoveryRatingFilterSection(data: ratings),
            const SizedBox(height: CandySpacing.cardGap),
            DiscoveryMetadataFilterSection(data: metadata),
            const SizedBox(height: CandySpacing.cardGap),
            DiscoveryPresetFilterSection(data: presets),
            const SizedBox(height: CandySpacing.cardGap),
            FilledButton(
              key: WidgetKeys.discoveryApplyFilters,
              onPressed: onApply,
              child: Text(l10n.discoveryApplyFiltersLabel),
            ),
          ],
        ),
      ),
    );
  }
}
