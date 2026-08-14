import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_mode.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_state.dart';
import 'package:jellyfin_picker/features/discovery/presentation/discovery_page.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_grid.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_shuffle.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_swipe.dart';

final class DiscoveryModeSwitcher extends StatelessWidget {
  const DiscoveryModeSwitcher({
    this.onToggleFavorite,
    this.onLoadDetails,
    this.onLoadMore,
    this.imageHeaders = const <String, String>{},
    super.key,
  });

  final Future<bool> Function(CatalogCandidate candidate)? onToggleFavorite;
  final CandidateDetailsLoader? onLoadDetails;
  final Future<void> Function()? onLoadMore;
  final Map<String, String> imageHeaders;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return BlocBuilder<DiscoveryCubit, DiscoveryState>(
      builder: (context, state) => AnimatedSwitcher(
        key: WidgetKeys.discoveryModeTransition,
        duration: reduceMotion ? Duration.zero : CandyMotion.standard,
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: KeyedSubtree(
          key: ValueKey<DiscoveryMode>(state.mode),
          child: switch (state.mode) {
            DiscoveryMode.grid => DiscoveryGrid(
              candidates: state.filteredCandidates,
              onToggleFavorite: onToggleFavorite,
              onLoadDetails: onLoadDetails,
              onLoadMore: onLoadMore,
              imageHeaders: imageHeaders,
            ),
            DiscoveryMode.swipe => DiscoverySwipe(
              candidates: state.undecidedCandidates,
              onToggleFavorite: onToggleFavorite,
              onLoadDetails: onLoadDetails,
              imageHeaders: imageHeaders,
            ),
            DiscoveryMode.shuffle => DiscoveryShuffle(
              state: state,
              onToggleFavorite: onToggleFavorite,
              onLoadDetails: onLoadDetails,
              imageHeaders: imageHeaders,
            ),
          },
        ),
      ),
    );
  }
}
