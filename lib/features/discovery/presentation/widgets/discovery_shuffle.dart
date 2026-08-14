import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_state.dart';
import 'package:jellyfin_picker/features/discovery/presentation/discovery_page.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_candidate_card.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

final class DiscoveryShuffle extends StatelessWidget {
  const DiscoveryShuffle({
    required this.state,
    this.onToggleFavorite,
    this.onLoadDetails,
    this.onOpenTrailer,
    this.imageHeaders = const <String, String>{},
    super.key,
  });

  final DiscoveryState state;
  final FavoriteToggle? onToggleFavorite;
  final CandidateDetailsLoader? onLoadDetails;
  final TrailerLauncher? onOpenTrailer;
  final Map<String, String> imageHeaders;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final candidate = _revealedCandidate;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Column(
      key: WidgetKeys.discoveryShuffle,
      spacing: CandySpacing.compact,
      children: <Widget>[
        Expanded(
          child: AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : CandyMotion.standard,
            switchInCurve: Curves.elasticOut,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: candidate == null
                ? Center(
                    key: WidgetKeys.discoveryShufflePlaceholder,
                    child: Icon(
                      Icons.casino_outlined,
                      size: CandySpacing.minimumTouchTarget,
                      semanticLabel: localization.discoveryShuffleLabel,
                    ),
                  )
                : DiscoveryCandidateCard(
                    key: WidgetKeys.discoveryShuffleCandidate(candidate.id),
                    candidate: candidate,
                    onToggleFavorite: onToggleFavorite,
                    onLoadDetails: onLoadDetails,
                    onOpenTrailer: onOpenTrailer,
                    imageHeaders: imageHeaders,
                    posterFit: BoxFit.contain,
                  ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: WidgetKeys.discoveryRevealButton,
            onPressed: () => context.read<DiscoveryCubit>().revealNext(),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(localization.discoveryRevealLabel),
          ),
        ),
      ],
    );
  }

  CatalogCandidate? get _revealedCandidate {
    final id = state.currentRevealId;
    if (id == null) {
      return null;
    }
    return state.candidates
        .where((candidate) => candidate.id == id)
        .firstOrNull;
  }
}
