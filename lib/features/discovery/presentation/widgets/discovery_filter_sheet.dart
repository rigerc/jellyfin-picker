import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_sheet_state.dart';

Future<void> showDiscoveryFilters(
  BuildContext context,
  CatalogFilter filter, {
  Iterable<CatalogCandidate> candidates = const <CatalogCandidate>[],
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => BlocProvider.value(
    value: context.read<DiscoveryCubit>(),
    child: DiscoveryFilterSheet(filter: filter, candidates: candidates),
  ),
);
