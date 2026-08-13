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
    final destinations = <({Key key, String label, IconData icon})>[
      (
        key: WidgetKeys.discoveryGridMode,
        label: localization.discoveryGridLabel,
        icon: Icons.grid_view_rounded,
      ),
      (
        key: WidgetKeys.discoverySwipeMode,
        label: localization.discoverySwipeLabel,
        icon: Icons.swipe_rounded,
      ),
      (
        key: WidgetKeys.discoveryShuffleMode,
        label: localization.discoveryShuffleLabel,
        icon: Icons.casino_outlined,
      ),
    ];
    return NavigationBar(
      key: WidgetKeys.discoveryModeNavigation,
      selectedIndex: DiscoveryMode.values.indexOf(selected),
      destinations: destinations
          .map(
            (destination) => NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
              key: destination.key,
            ),
          )
          .toList(growable: false),
      onDestinationSelected: (index) =>
          context.read<DiscoveryCubit>().setMode(DiscoveryMode.values[index]),
    );
  }
}
