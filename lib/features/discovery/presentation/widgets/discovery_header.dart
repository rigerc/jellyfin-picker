import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

final class DiscoveryHeader extends StatelessWidget {
  const DiscoveryHeader({
    required this.candidateCount,
    required this.onOpenFilters,
    required this.onClear,
    super.key,
  });

  final int candidateCount;
  final VoidCallback onOpenFilters;
  final VoidCallback onClear;

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
                SizedBox.square(
                  dimension: CandySpacing.minimumTouchTarget,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.theaters_rounded,
                      color: colorScheme.onSecondaryContainer,
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
          ],
        ),
      ),
    );
  }
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
          icon: const Icon(Icons.tune_rounded),
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
