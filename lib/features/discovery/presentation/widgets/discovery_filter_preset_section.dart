import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_models.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_sections.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

final class DiscoveryPresetFilterSection extends StatelessWidget {
  const DiscoveryPresetFilterSection({required this.data, super.key});

  final DiscoveryPresetFilterData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DiscoveryFilterSection(
      title: l10n.discoveryPresetsLabel,
      icon: Icons.bookmarks_outlined,
      child: Column(
        spacing: CandySpacing.compact,
        children: <Widget>[
          if (data.presets.isNotEmpty)
            Wrap(
              spacing: CandySpacing.compact,
              runSpacing: CandySpacing.compact,
              children: data.presets.keys
                  .map(
                    (name) => ActionChip(
                      key: WidgetKeys.discoveryPreset(name),
                      label: Text(name),
                      onPressed: () => data.onApply(name),
                    ),
                  )
                  .toList(growable: false),
            ),
          TextField(
            key: WidgetKeys.discoveryPresetName,
            controller: data.nameController,
            maxLength: 50,
            decoration: InputDecoration(
              labelText: l10n.discoveryPresetNameLabel,
            ),
          ),
          OutlinedButton.icon(
            key: WidgetKeys.discoverySavePreset,
            onPressed: data.onSave,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(l10n.discoverySavePresetLabel),
          ),
        ],
      ),
    );
  }
}
