import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_state.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_sheet.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_header.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_mode_selector.dart';

final class DiscoveryControls extends StatelessWidget {
  const DiscoveryControls({required this.onClear, super.key});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        spacing: CandySpacing.cardGap,
        children: <Widget>[
          BlocBuilder<DiscoveryCubit, DiscoveryState>(
            buildWhen: (previous, current) =>
                previous.filteredCandidates.length !=
                    current.filteredCandidates.length ||
                previous.filter != current.filter,
            builder: (context, state) => DiscoveryHeader(
              candidateCount: state.filteredCandidates.length,
              filter: state.filter,
              onFilterChanged: context.read<DiscoveryCubit>().updateFilter,
              onOpenFilters: () => showDiscoveryFilters(
                context,
                state.filter,
                candidates: state.candidates,
              ),
              onClear: onClear,
            ),
          ),
          const DiscoveryModeSelector(),
        ],
      ),
    );
  }
}
