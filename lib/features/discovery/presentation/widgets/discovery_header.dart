import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/assets/app_assets.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_filter.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_header_actions.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

final class DiscoveryHeader extends StatelessWidget {
  const DiscoveryHeader({
    required this.candidateCount,
    required this.onOpenFilters,
    required this.onClear,
    required this.filter,
    super.key,
  });

  final int candidateCount;
  final VoidCallback onOpenFilters;
  final VoidCallback onClear;
  final CatalogFilter filter;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(CandySpacing.compact),
        child: Row(
          spacing: CandySpacing.compact,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(CandyShapes.poster),
              child: ExcludeSemantics(
                child: Image.asset(
                  AppAssets.appIcon,
                  width: CandyIconSize.action,
                  height: CandyIconSize.action,
                  cacheWidth: CandyImages.artworkCacheWidth,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    localization.discoveryTitle,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    localization.discoveryCandidateCount(candidateCount),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            DiscoveryHeaderActions(
              filterActive: filter.isActive,
              onOpenFilters: onOpenFilters,
              onClear: onClear,
            ),
          ],
        ),
      ),
    );
  }
}
