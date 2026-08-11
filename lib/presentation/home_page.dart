import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

/// The first destination shown by the app shell.
final class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      key: WidgetKeys.appShell,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CandySpacing.page),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: CandySpacing.compact,
              children: <Widget>[
                Text(
                  localization.appTitle,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                Text(
                  localization.homeHeadline,
                  style: theme.textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                Text(
                  localization.homeDescription,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
