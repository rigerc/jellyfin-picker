import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/discovery/presentation/discovery_page.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_candidate_card.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_empty_state.dart';

final class DiscoveryGrid extends StatelessWidget {
  const DiscoveryGrid({
    required this.candidates,
    this.onToggleFavorite,
    this.onLoadDetails,
    this.onOpenTrailer,
    this.onLoadMore,
    this.imageHeaders = const <String, String>{},
    super.key,
  });

  final List<CatalogCandidate> candidates;
  final FavoriteToggle? onToggleFavorite;
  final CandidateDetailsLoader? onLoadDetails;
  final TrailerLauncher? onOpenTrailer;
  final Future<void> Function()? onLoadMore;
  final Map<String, String> imageHeaders;

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) {
      return const DiscoveryEmptyState();
    }
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 700
        ? 4
        : width >= 480
        ? 3
        : 2;
    return NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter <= CandySpacing.section) {
          onLoadMore?.call();
        }
        return false;
      },
      child: GridView.builder(
        key: WidgetKeys.discoveryGrid,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: CandySpacing.cardGap,
          crossAxisSpacing: CandySpacing.cardGap,
          childAspectRatio: CandyShapes.gridCardRatio,
        ),
        itemCount: candidates.length,
        itemBuilder: (context, index) => RepaintBoundary(
          key: ValueKey<String>(candidates[index].id),
          child: DiscoveryCandidateCard(
            candidate: candidates[index],
            onToggleFavorite: onToggleFavorite,
            onLoadDetails: onLoadDetails,
            onOpenTrailer: onOpenTrailer,
            imageHeaders: imageHeaders,
          ),
        ),
      ),
    );
  }
}
