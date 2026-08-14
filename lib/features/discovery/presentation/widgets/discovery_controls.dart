import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_facets.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_library.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_state.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_sheet.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_header.dart';

final class DiscoveryControls extends StatelessWidget {
  const DiscoveryControls({
    required this.onClear,
    this.libraries = const <CatalogLibrary>[],
    this.facets = const CatalogFacets(),
    super.key,
  });

  final VoidCallback onClear;
  final List<CatalogLibrary> libraries;
  final CatalogFacets facets;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryCubit, DiscoveryState>(
      buildWhen: (previous, current) =>
          previous.filteredCandidates.length !=
              current.filteredCandidates.length ||
          previous.filter != current.filter,
      builder: (context, state) => DiscoveryHeader(
        candidateCount: state.filteredCandidates.length,
        filter: state.filter,
        onOpenFilters: () => showDiscoveryFilters(
          context,
          state.filter,
          candidates: state.candidates,
          libraries: libraries,
          facets: facets,
        ),
        onClear: onClear,
      ),
    );
  }
}
