import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

final class DiscoveryHeaderActions extends StatelessWidget {
  const DiscoveryHeaderActions({
    required this.filterActive,
    required this.onOpenFilters,
    required this.onClear,
    super.key,
  });

  final bool filterActive;
  final VoidCallback onOpenFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    const filterIcon = Icon(Icons.filter_list_rounded);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          key: WidgetKeys.discoveryFilterButton,
          tooltip: filterActive
              ? localization.discoveryActiveFilterLabel
              : localization.discoveryFiltersLabel,
          onPressed: onOpenFilters,
          icon: filterActive
              ? Badge(
                  key: WidgetKeys.discoveryActiveFilterIndicator,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: filterIcon,
                )
              : filterIcon,
        ),
        PopupMenuButton<void>(
          key: WidgetKeys.discoveryMoreButton,
          tooltip: localization.discoveryMoreActionsLabel,
          icon: const Icon(Icons.more_horiz_rounded),
          itemBuilder: (context) => <PopupMenuEntry<void>>[
            PopupMenuItem<void>(
              key: WidgetKeys.discoveryClearButton,
              onTap: onClear,
              child: Row(
                spacing: CandySpacing.compact,
                children: <Widget>[
                  const Icon(Icons.delete_sweep_outlined),
                  Expanded(child: Text(localization.discoveryClearLabel)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
