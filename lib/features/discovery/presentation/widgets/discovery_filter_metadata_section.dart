import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_models.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_sections.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

final class DiscoveryMetadataFilterSection extends StatelessWidget {
  const DiscoveryMetadataFilterSection({required this.data, super.key});

  final DiscoveryMetadataFilterData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DiscoveryFilterSection(
      title: l10n.discoveryLibraryDetailsLabel,
      icon: Icons.category_outlined,
      child: Column(
        spacing: CandySpacing.cardGap,
        children: <Widget>[
          if (data.availableGenres.isNotEmpty)
            DiscoveryMetadataChoices<String>(
              label: l10n.discoveryGenresFilterLabel,
              values: data.availableGenres,
              selected: data.genres,
              keyFor: WidgetKeys.discoveryGenre,
              onChanged: data.onGenreChanged,
            )
          else
            TextField(
              key: WidgetKeys.discoveryGenresField,
              controller: data.genresController,
              decoration: InputDecoration(
                labelText: l10n.discoveryGenresFilterLabel,
              ),
            ),
          if (data.availableRatings.isNotEmpty)
            DiscoveryMetadataChoices<String>(
              label: l10n.discoveryOfficialRatingsFilterLabel,
              values: data.availableRatings,
              selected: data.officialRatings,
              keyFor: WidgetKeys.discoveryOfficialRating,
              onChanged: data.onOfficialRatingChanged,
            ),
          if (data.availableDecades.isNotEmpty)
            DiscoveryMetadataChoices<int>(
              label: l10n.discoveryDecadeFilterLabel,
              values: data.availableDecades,
              selected: data.decades,
              keyFor: WidgetKeys.discoveryDecade,
              labelFor: (value) => '${value}s',
              onChanged: data.onDecadeChanged,
            ),
          DiscoveryTriStateField(
            key: WidgetKeys.discoveryWatchedField,
            label: l10n.discoveryWatchedFilterLabel,
            value: data.watched,
            onChanged: data.onWatchedChanged,
          ),
          DiscoveryTriStateField(
            key: WidgetKeys.discoveryFavoriteField,
            label: l10n.discoveryFavoriteFilterLabel,
            value: data.favorite,
            onChanged: data.onFavoriteChanged,
          ),
        ],
      ),
    );
  }
}
