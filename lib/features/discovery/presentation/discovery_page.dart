import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_mode.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_state.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_grid.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_sheet.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_mode_selector.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_shuffle.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_swipe.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

typedef FavoriteToggle = Future<bool> Function(CatalogCandidate candidate);

final class DiscoveryPage extends StatelessWidget {
  const DiscoveryPage({
    required this.cubit,
    this.onToggleFavorite,
    this.imageHeaders = const <String, String>{},
    super.key,
  });

  final DiscoveryCubit cubit;
  final FavoriteToggle? onToggleFavorite;
  final Map<String, String> imageHeaders;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: _DiscoveryView(
        onToggleFavorite: onToggleFavorite,
        imageHeaders: imageHeaders,
      ),
    );
  }
}

final class _DiscoveryView extends StatelessWidget {
  const _DiscoveryView({required this.imageHeaders, this.onToggleFavorite});

  final FavoriteToggle? onToggleFavorite;
  final Map<String, String> imageHeaders;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      key: WidgetKeys.discoveryPage,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CandySpacing.page),
          child: Column(
            spacing: CandySpacing.compact,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      localization.discoveryTitle,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    key: WidgetKeys.discoveryFilterButton,
                    tooltip: localization.discoveryFiltersLabel,
                    onPressed: () => showDiscoveryFilters(
                      context,
                      context.read<DiscoveryCubit>().state.filter,
                    ),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                  IconButton(
                    key: WidgetKeys.discoveryClearButton,
                    tooltip: localization.discoveryClearLabel,
                    onPressed: () => _confirmClear(context),
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
                ],
              ),
              const DiscoveryModeSelector(),
              Expanded(
                child: BlocBuilder<DiscoveryCubit, DiscoveryState>(
                  builder: (context, state) => switch (state.mode) {
                    DiscoveryMode.grid => DiscoveryGrid(
                      candidates: state.filteredCandidates,
                      onToggleFavorite: onToggleFavorite,
                      imageHeaders: imageHeaders,
                    ),
                    DiscoveryMode.swipe => DiscoverySwipe(
                      candidates: state.undecidedCandidates,
                      onToggleFavorite: onToggleFavorite,
                      imageHeaders: imageHeaders,
                    ),
                    DiscoveryMode.shuffle => DiscoveryShuffle(
                      state: state,
                      onToggleFavorite: onToggleFavorite,
                      imageHeaders: imageHeaders,
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final localization = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(localization.discoveryClearConfirmation),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localization.discoveryCancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(localization.discoveryConfirmClearLabel),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<DiscoveryCubit>().clearDiscovery();
    }
  }
}
