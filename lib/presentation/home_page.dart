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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CandySpacing.page),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: CandyLayout.contentMaxWidth,
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(CandySpacing.section),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: CandySpacing.compact,
                    children: <Widget>[
                      ExcludeSemantics(
                        child: Icon(
                          Icons.movie_filter_rounded,
                          size: CandyIconSize.hero,
                          color: theme.colorScheme.primary,
                        ),
                      ),
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
          ),
        ),
      ),
    );
  }
}
