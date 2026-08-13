import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

final class DiscoveryDetailsMetadata extends StatelessWidget {
  const DiscoveryDetailsMetadata({required this.candidate, super.key});

  final CatalogCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final unknown = localization.discoveryUnknownValue;
    final runtime = candidate.runtimeMinutes;
    final genres = candidate.genres.isEmpty
        ? unknown
        : candidate.genres.map(_titleCase).join(', ');
    final cast = candidate.cast.isEmpty
        ? unknown
        : candidate.cast.take(5).join(', ');
    final details = <String>[
      localization.discoveryYearLabel(candidate.year?.toString() ?? unknown),
      localization.discoveryRuntimeLabel(
        runtime == null
            ? unknown
            : localization.discoveryRuntimeMinutes(runtime),
      ),
      localization.discoveryGenresLabel(genres),
      localization.discoveryCommunityRatingLabel(
        candidate.communityRating?.toStringAsFixed(1) ?? unknown,
      ),
      localization.discoveryCriticRatingLabel(
        candidate.criticRating?.toStringAsFixed(0) ?? unknown,
      ),
      localization.discoveryContentRatingLabel(
        candidate.officialRating ?? unknown,
      ),
      localization.discoveryStatusLabel(candidate.status ?? unknown),
      localization.discoveryCastLabel(cast),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: CandySpacing.compact,
      children: details.map(Text.new).toList(growable: false),
    );
  }

  String _titleCase(String value) => value.isEmpty
      ? value
      : '${value.substring(0, 1).toUpperCase()}${value.substring(1)}';
}
