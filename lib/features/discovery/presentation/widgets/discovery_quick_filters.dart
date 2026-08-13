import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_models.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_sections.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

final class DiscoveryQuickFilters extends StatelessWidget {
  const DiscoveryQuickFilters({required this.data, super.key});

  final DiscoveryQuickFilterData data;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final filters =
        <
          ({
            Key key,
            String label,
            bool selected,
            ValueChanged<bool> onSelected,
          })
        >[
          (
            key: WidgetKeys.discoveryRecentFilter,
            label: localization.discoveryQuickRecentLabel,
            selected: data.recent,
            onSelected: data.onRecentChanged,
          ),
          (
            key: WidgetKeys.discoveryUnwatchedFilter,
            label: localization.discoveryQuickUnwatchedLabel,
            selected: data.unwatched,
            onSelected: data.onUnwatchedChanged,
          ),
          (
            key: WidgetKeys.discoveryFavoritesFilter,
            label: localization.discoveryQuickFavoritesLabel,
            selected: data.favorites,
            onSelected: data.onFavoritesChanged,
          ),
        ];
    return DiscoveryFilterSection(
      title: localization.discoveryQuickFiltersLabel,
      icon: Icons.bolt_rounded,
      child: Wrap(
        spacing: CandySpacing.compact,
        runSpacing: CandySpacing.compact,
        children: filters
            .map(
              (filter) => FilterChip(
                key: filter.key,
                label: Text(filter.label),
                selected: filter.selected,
                onSelected: filter.onSelected,
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
