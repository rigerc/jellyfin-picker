import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/features/discovery/presentation/discovery_page.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_candidate_card.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_empty_state.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

final class DiscoverySwipe extends StatelessWidget {
  const DiscoverySwipe({
    required this.candidates,
    this.onToggleFavorite,
    this.imageHeaders = const <String, String>{},
    super.key,
  });

  final List<CatalogCandidate> candidates;
  final FavoriteToggle? onToggleFavorite;
  final Map<String, String> imageHeaders;

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) {
      return const DiscoveryEmptyState();
    }
    final candidate = candidates.first;
    final localization = AppLocalizations.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Column(
      key: WidgetKeys.discoverySwipeDeck,
      spacing: CandySpacing.compact,
      children: <Widget>[
        Expanded(
          child: Dismissible(
            key: ValueKey<String>('swipe-${candidate.id}'),
            movementDuration: reduceMotion
                ? Duration.zero
                : CandyMotion.standard,
            resizeDuration: reduceMotion ? Duration.zero : CandyMotion.quick,
            onDismissed: (direction) => _decide(context, candidate, direction),
            child: DiscoveryCandidateCard(
              candidate: candidate,
              onToggleFavorite: onToggleFavorite,
              imageHeaders: imageHeaders,
              posterFit: BoxFit.contain,
            ),
          ),
        ),
        Row(
          spacing: CandySpacing.compact,
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.read<DiscoveryCubit>().reject(candidate.id),
                icon: const Icon(Icons.close_rounded),
                label: Text(localization.discoveryRejectLabel),
              ),
            ),
            Expanded(
              child: FilledButton.icon(
                onPressed: () =>
                    context.read<DiscoveryCubit>().like(candidate.id),
                icon: const Icon(Icons.favorite_rounded),
                label: Text(localization.discoveryLikeLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _decide(
    BuildContext context,
    CatalogCandidate candidate,
    DismissDirection direction,
  ) {
    if (direction == DismissDirection.startToEnd) {
      context.read<DiscoveryCubit>().like(candidate.id);
    } else {
      context.read<DiscoveryCubit>().reject(candidate.id);
    }
  }
}
