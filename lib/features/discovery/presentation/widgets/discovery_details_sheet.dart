import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

Future<void> showDiscoveryDetails(
  BuildContext context,
  CatalogCandidate candidate,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * 0.9,
  ),
  showDragHandle: true,
  builder: (context) => DiscoveryDetailsSheet(candidate: candidate),
);

final class DiscoveryDetailsSheet extends StatelessWidget {
  const DiscoveryDetailsSheet({required this.candidate, super.key});

  final CatalogCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final unknown = localization.discoveryUnknownValue;
    final genres = candidate.genres.isEmpty
        ? unknown
        : candidate.genres.map(_titleCase).join(', ');
    final cast = candidate.cast.isEmpty
        ? unknown
        : candidate.cast.take(5).join(', ');
    final runtime = candidate.runtimeMinutes;
    return SafeArea(
      child: ListView(
        key: WidgetKeys.discoveryDetails,
        shrinkWrap: true,
        padding: const EdgeInsets.all(CandySpacing.page),
        children: <Widget>[
          Text(
            candidate.name,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: CandySpacing.cardGap),
          Text(localization.discoverySynopsisLabel),
          Text(candidate.overview ?? unknown),
          const SizedBox(height: CandySpacing.cardGap),
          ...<String>[
            localization.discoveryYearLabel(
              candidate.year?.toString() ?? unknown,
            ),
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
          ].map(
            (value) => Padding(
              padding: const EdgeInsets.only(bottom: CandySpacing.compact),
              child: Text(value),
            ),
          ),
        ],
      ),
    );
  }

  String _titleCase(String value) => value.isEmpty
      ? value
      : '${value.substring(0, 1).toUpperCase()}${value.substring(1)}';
}
