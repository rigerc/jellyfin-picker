import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_facets.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_library.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_sheet_state.dart';

Future<void> showDiscoveryFilters(
  BuildContext context,
  CatalogFilter filter, {
  Iterable<CatalogCandidate> candidates = const <CatalogCandidate>[],
  List<CatalogLibrary> libraries = const <CatalogLibrary>[],
  CatalogFacets facets = const CatalogFacets(),
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => BlocProvider.value(
    value: context.read<DiscoveryCubit>(),
    child: DiscoveryFilterSheet(
      filter: filter,
      candidates: candidates,
      libraries: libraries,
      facets: facets,
    ),
  ),
);
