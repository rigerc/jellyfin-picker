import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/core/widgets/candy_bounce.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/features/discovery/presentation/discovery_page.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_details_sheet.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

final class DiscoveryCandidateCard extends StatelessWidget {
  const DiscoveryCandidateCard({
    required this.candidate,
    this.onToggleFavorite,
    this.onLoadDetails,
    this.onOpenTrailer,
    this.imageHeaders = const <String, String>{},
    this.posterFit = BoxFit.cover,
    super.key,
  });

  final CatalogCandidate candidate;
  final FavoriteToggle? onToggleFavorite;
  final CandidateDetailsLoader? onLoadDetails;
  final TrailerLauncher? onOpenTrailer;
  final Map<String, String> imageHeaders;
  final BoxFit posterFit;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      label: localization.discoveryDetailsLabel(candidate.name),
      child: CandyBounce(
        key: WidgetKeys.discoveryCandidate(candidate.id),
        onPressed: () => showDiscoveryDetails(
          context,
          candidate,
          onLoadDetails: onLoadDetails,
          onOpenTrailer: onOpenTrailer,
        ),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: _Poster(
                  candidate: candidate,
                  headers: imageHeaders,
                  fit: posterFit,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(CandySpacing.compact),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        candidate.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      key: WidgetKeys.discoveryFavorite(candidate.id),
                      tooltip: candidate.favorite == true
                          ? localization.discoveryFavoriteRemoveLabel
                          : localization.discoveryFavoriteAddLabel,
                      onPressed: onToggleFavorite == null
                          ? null
                          : () => _toggleFavorite(context),
                      icon: Icon(
                        candidate.favorite == true
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    final succeeded = await onToggleFavorite?.call(candidate) ?? false;
    if (succeeded && context.mounted) {
      await context.read<DiscoveryCubit>().updateCandidate(
        candidate.copyWith(favorite: candidate.favorite != true),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).discoveryFavoriteError),
        ),
      );
    }
  }
}

final class _Poster extends StatelessWidget {
  const _Poster({
    required this.candidate,
    required this.headers,
    required this.fit,
  });

  final CatalogCandidate candidate;
  final Map<String, String> headers;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final previewUri = candidate.poster.variantUri(
      maxWidth: CandyImages.posterPreviewNetworkWidth,
      quality: CandyImages.posterPreviewQuality,
      blur: CandyImages.posterPreviewBlur,
    );
    final displayUri = candidate.poster.variantUri(
      maxWidth: CandyImages.posterDisplayNetworkWidth,
      quality: CandyImages.posterDisplayQuality,
    );
    if (previewUri == null || displayUri == null) {
      return const _PosterFallback();
    }
    final blurHash = candidate.poster.blurHash;
    final placeholder = blurHash != null && validateBlurhash(blurHash)
        ? BlurHash(
            key: WidgetKeys.discoveryPosterBlurHash(candidate.id),
            hash: blurHash,
            color: Theme.of(context).colorScheme.tertiaryContainer,
            imageFit: fit,
            decodingWidth: 20,
            decodingHeight: (20 / candidate.poster.aspectRatio).round().clamp(
              1,
              32,
            ),
            optimizationMode: BlurHashOptimizationMode.approximation,
          )
        : Image.network(
            previewUri.toString(),
            key: WidgetKeys.discoveryPosterPreview,
            headers: headers,
            fit: fit,
            cacheWidth: CandyImages.posterPreviewNetworkWidth,
            filterQuality: FilterQuality.low,
            errorBuilder: (context, error, stackTrace) =>
                const _PosterFallback(),
          );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        placeholder,
        Image.network(
          displayUri.toString(),
          headers: headers,
          fit: fit,
          cacheWidth: CandyImages.posterCacheWidth,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) {
              return child;
            }
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: reduceMotion ? Duration.zero : CandyMotion.quick,
              curve: Curves.easeOutCubic,
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

final class _PosterFallback extends StatelessWidget {
  const _PosterFallback();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.tertiaryContainer,
    child: const Center(child: Icon(Icons.local_movies_outlined)),
  );
}
