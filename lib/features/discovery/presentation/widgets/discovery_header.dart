import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/assets/app_assets.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_filter.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

final class DiscoveryHeader extends StatelessWidget {
  const DiscoveryHeader({
    required this.candidateCount,
    required this.onOpenFilters,
    required this.onClear,
    required this.filter,
    required this.onFilterChanged,
    super.key,
  });

  final int candidateCount;
  final VoidCallback onOpenFilters;
  final VoidCallback onClear;
  final CatalogFilter filter;
  final ValueChanged<CatalogFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(CandySpacing.cardGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CandySpacing.compact,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(CandyShapes.card),
                  child: ExcludeSemantics(
                    child: Image.asset(
                      AppAssets.appIcon,
                      width: CandySpacing.minimumTouchTarget,
                      height: CandySpacing.minimumTouchTarget,
                      cacheWidth: CandyImages.artworkCacheWidth,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                const SizedBox(width: CandySpacing.compact),
                Expanded(
                  child: Text(
                    localization.appTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                _DiscoveryActions(
                  onOpenFilters: onOpenFilters,
                  onClear: onClear,
                ),
              ],
            ),
            Text(
              localization.discoveryTitle,
              style: theme.textTheme.titleLarge,
            ),
            Text(
              localization.discoveryHeaderSubtitle(candidateCount),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            _DiscoveryQuickFilters(
              filter: filter,
              onFilterChanged: onFilterChanged,
            ),
          ],
        ),
      ),
    );
  }
}

final class _DiscoveryQuickFilters extends StatelessWidget {
  const _DiscoveryQuickFilters({
    required this.filter,
    required this.onFilterChanged,
  });

  final CatalogFilter filter;
  final ValueChanged<CatalogFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return SizedBox(
      height: CandySpacing.minimumTouchTarget,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: CandySpacing.compact,
          children: <Widget>[
            _QuickFilterChip(
              key: WidgetKeys.discoveryRecentFilter,
              label: localization.discoveryQuickRecentLabel,
              selected: filter.addedWithin == CatalogAddedWindow.thirtyDays,
              onSelected: (selected) => onFilterChanged(
                filter.copyWith(
                  addedWithin: selected ? CatalogAddedWindow.thirtyDays : null,
                ),
              ),
            ),
            _QuickFilterChip(
              key: WidgetKeys.discoveryUnwatchedFilter,
              label: localization.discoveryQuickUnwatchedLabel,
              selected: filter.watched == false,
              onSelected: (selected) => onFilterChanged(
                filter.copyWith(watched: selected ? false : null),
              ),
            ),
            _QuickFilterChip(
              key: WidgetKeys.discoveryFavoritesFilter,
              label: localization.discoveryQuickFavoritesLabel,
              selected: filter.favorite == true,
              onSelected: (selected) => onFilterChanged(
                filter.copyWith(favorite: selected ? true : null),
              ),
            ),
            if (filter.isActive)
              Semantics(
                label: localization.discoveryActiveFilterLabel,
                liveRegion: true,
                child: Chip(
                  key: WidgetKeys.discoveryActiveFilterIndicator,
                  avatar: const Icon(Icons.filter_alt_outlined),
                  label: Text(localization.discoveryActiveFilterLabel),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: onSelected,
    padding: const EdgeInsets.symmetric(horizontal: CandySpacing.compact),
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}

final class _DiscoveryActions extends StatelessWidget {
  const _DiscoveryActions({required this.onOpenFilters, required this.onClear});

  final VoidCallback onOpenFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          key: WidgetKeys.discoveryFilterButton,
          tooltip: localization.discoveryFiltersLabel,
          onPressed: onOpenFilters,
          icon: ClipRRect(
            borderRadius: BorderRadius.circular(CandyShapes.poster),
            child: ExcludeSemantics(
              child: Image.asset(
                AppAssets.filterIcon,
                width: CandyIconSize.action,
                height: CandyIconSize.action,
                cacheWidth: CandyImages.artworkCacheWidth,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
        IconButton(
          key: WidgetKeys.discoveryClearButton,
          tooltip: localization.discoveryClearLabel,
          onPressed: onClear,
          icon: const Icon(Icons.delete_sweep_outlined),
        ),
      ],
    );
  }
}
