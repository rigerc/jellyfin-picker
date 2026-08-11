import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

final class DiscoveryEmptyState extends StatelessWidget {
  const DiscoveryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CandySpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: CandySpacing.compact,
          children: <Widget>[
            const Icon(Icons.auto_awesome_outlined),
            Text(
              localization.discoveryNoCandidatesTitle,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            Text(
              localization.discoveryNoCandidatesDescription,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
