import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

enum DiscoveryTriState { any, yes, no }

final class DiscoveryMetadataChoices<T> extends StatelessWidget {
  const DiscoveryMetadataChoices({
    required this.label,
    required this.values,
    required this.selected,
    required this.keyFor,
    required this.onChanged,
    this.labelFor,
    super.key,
  });

  final String label;
  final List<T> values;
  final Set<T> selected;
  final Key Function(T value) keyFor;
  final void Function(T value, bool selected) onChanged;
  final String Function(T value)? labelFor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: CandySpacing.compact,
    children: <Widget>[
      Text(label, style: Theme.of(context).textTheme.titleSmall),
      Wrap(
        spacing: CandySpacing.compact,
        runSpacing: CandySpacing.compact,
        children: values
            .map(
              (value) => FilterChip(
                key: keyFor(value),
                label: Text(labelFor?.call(value) ?? '$value'),
                selected: selected.contains(value),
                onSelected: (selected) => onChanged(value, selected),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
            )
            .toList(growable: false),
      ),
    ],
  );
}

final class DiscoveryFilterSection extends StatelessWidget {
  const DiscoveryFilterSection({
    required this.title,
    required this.icon,
    required this.child,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(CandySpacing.cardGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CandySpacing.compact,
        children: <Widget>[
          Row(
            spacing: CandySpacing.compact,
            children: <Widget>[
              Icon(icon),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    ),
  );
}

final class DiscoveryTriStateField extends StatelessWidget {
  const DiscoveryTriStateField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final DiscoveryTriState value;
  final ValueChanged<DiscoveryTriState> onChanged;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return DropdownButtonFormField<DiscoveryTriState>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: <DropdownMenuItem<DiscoveryTriState>>[
        DropdownMenuItem<DiscoveryTriState>(
          value: DiscoveryTriState.any,
          child: Text(localization.discoveryAnyLabel),
        ),
        DropdownMenuItem<DiscoveryTriState>(
          value: DiscoveryTriState.yes,
          child: Text(localization.discoveryYesLabel),
        ),
        DropdownMenuItem<DiscoveryTriState>(
          value: DiscoveryTriState.no,
          child: Text(localization.discoveryNoLabel),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
