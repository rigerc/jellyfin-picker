import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/features/discovery/presentation/discovery_page.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_details_sheet.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

final class DiscoveryCandidateCard extends StatelessWidget {
  const DiscoveryCandidateCard({
    required this.candidate,
    this.onToggleFavorite,
    this.imageHeaders = const <String, String>{},
    super.key,
  });

  final CatalogCandidate candidate;
  final FavoriteToggle? onToggleFavorite;
  final Map<String, String> imageHeaders;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        label: localization.discoveryDetailsLabel(candidate.name),
        child: InkWell(
          key: WidgetKeys.discoveryCandidate(candidate.id),
          onTap: () => showDiscoveryDetails(context, candidate),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: _Poster(candidate: candidate, headers: imageHeaders),
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
  const _Poster({required this.candidate, required this.headers});

  final CatalogCandidate candidate;
  final Map<String, String> headers;

  @override
  Widget build(BuildContext context) {
    final uri = candidate.poster.uri;
    if (uri == null || candidate.poster.isFallback) {
      return const _PosterFallback();
    }
    return Image.network(
      uri.toString(),
      headers: headers,
      fit: BoxFit.cover,
      cacheWidth: CandyImages.posterCacheWidth,
      errorBuilder: (context, error, stackTrace) => const _PosterFallback(),
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
