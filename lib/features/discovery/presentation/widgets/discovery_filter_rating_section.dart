import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_models.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_sections.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

final class DiscoveryRatingFilterSection extends StatelessWidget {
  const DiscoveryRatingFilterSection({required this.data, super.key});

  final DiscoveryRatingFilterData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DiscoveryFilterSection(
      title: l10n.discoveryFineTuneFiltersLabel,
      icon: Icons.tune_rounded,
      child: Column(
        spacing: CandySpacing.compact,
        children: <Widget>[
          Text(
            l10n.discoveryRuntimeFilterLabel(
              data.runtime.start.round(),
              data.runtime.end.round(),
            ),
          ),
          RangeSlider(
            key: WidgetKeys.discoveryRuntimeField,
            values: data.runtime,
            max: 300,
            onChanged: data.onRuntimeChanged,
          ),
          Text(
            l10n.discoveryCommunityFilterLabel(
              data.community.toStringAsFixed(1),
            ),
          ),
          Slider(
            key: WidgetKeys.discoveryCommunityRatingField,
            value: data.community,
            max: 10,
            onChanged: data.onCommunityChanged,
          ),
          Text(l10n.discoveryCriticFilterLabel(data.critic.toStringAsFixed(0))),
          Slider(
            key: WidgetKeys.discoveryCriticRatingField,
            value: data.critic,
            max: 100,
            onChanged: data.onCriticChanged,
          ),
        ],
      ),
    );
  }
}
