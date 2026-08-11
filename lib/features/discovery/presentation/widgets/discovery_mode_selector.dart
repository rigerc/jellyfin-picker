import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_mode.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

final class DiscoveryModeSelector extends StatelessWidget {
  const DiscoveryModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final selected = context.select((DiscoveryCubit cubit) => cubit.state.mode);
    return SegmentedButton<DiscoveryMode>(
      segments: <ButtonSegment<DiscoveryMode>>[
        ButtonSegment<DiscoveryMode>(
          value: DiscoveryMode.grid,
          label: Text(
            localization.discoveryGridLabel,
            key: WidgetKeys.discoveryGridMode,
          ),
          icon: const Icon(Icons.grid_view_rounded),
        ),
        ButtonSegment<DiscoveryMode>(
          value: DiscoveryMode.swipe,
          label: Text(
            localization.discoverySwipeLabel,
            key: WidgetKeys.discoverySwipeMode,
          ),
          icon: const Icon(Icons.swipe_rounded),
        ),
        ButtonSegment<DiscoveryMode>(
          value: DiscoveryMode.shuffle,
          label: Text(
            localization.discoveryShuffleLabel,
            key: WidgetKeys.discoveryShuffleMode,
          ),
          icon: const Icon(Icons.casino_outlined),
        ),
      ],
      selected: <DiscoveryMode>{selected},
      onSelectionChanged: (modes) =>
          context.read<DiscoveryCubit>().setMode(modes.single),
    );
  }
}
