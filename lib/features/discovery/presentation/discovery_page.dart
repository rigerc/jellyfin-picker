import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_facets.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_library.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_clear_dialog.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_controls.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_mode_selector.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_mode_switcher.dart';

typedef FavoriteToggle = Future<bool> Function(CatalogCandidate candidate);
typedef CandidateDetailsLoader =
    Future<CatalogCandidate?> Function(CatalogCandidate candidate);
typedef TrailerLauncher = Future<bool> Function(Uri uri);

final class DiscoveryPage extends StatelessWidget {
  const DiscoveryPage({
    required this.cubit,
    this.onToggleFavorite,
    this.onLoadDetails,
    this.onOpenTrailer,
    this.onLoadMore,
    this.libraries = const <CatalogLibrary>[],
    this.facets = const CatalogFacets(),
    this.imageHeaders = const <String, String>{},
    super.key,
  });

  final DiscoveryCubit cubit;
  final FavoriteToggle? onToggleFavorite;
  final CandidateDetailsLoader? onLoadDetails;
  final TrailerLauncher? onOpenTrailer;
  final Future<void> Function()? onLoadMore;
  final List<CatalogLibrary> libraries;
  final CatalogFacets facets;
  final Map<String, String> imageHeaders;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: _DiscoveryView(
        onToggleFavorite: onToggleFavorite,
        onLoadDetails: onLoadDetails,
        onOpenTrailer: onOpenTrailer,
        onLoadMore: onLoadMore,
        libraries: libraries,
        facets: facets,
        imageHeaders: imageHeaders,
      ),
    );
  }
}

final class _DiscoveryView extends StatelessWidget {
  const _DiscoveryView({
    required this.imageHeaders,
    required this.libraries,
    required this.facets,
    this.onToggleFavorite,
    this.onLoadDetails,
    this.onOpenTrailer,
    this.onLoadMore,
  });

  final FavoriteToggle? onToggleFavorite;
  final CandidateDetailsLoader? onLoadDetails;
  final TrailerLauncher? onOpenTrailer;
  final Future<void> Function()? onLoadMore;
  final List<CatalogLibrary> libraries;
  final CatalogFacets facets;
  final Map<String, String> imageHeaders;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: WidgetKeys.discoveryPage,
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: const DiscoveryModeSelector(),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CandySpacing.page,
            CandySpacing.page,
            CandySpacing.page,
            CandySpacing.compact,
          ),
          child: Column(
            spacing: CandySpacing.cardGap,
            children: <Widget>[
              DiscoveryControls(
                libraries: libraries,
                facets: facets,
                onClear: () => confirmClearDiscovery(context),
              ),
              Expanded(
                child: DiscoveryModeSwitcher(
                  onToggleFavorite: onToggleFavorite,
                  onLoadDetails: onLoadDetails,
                  onOpenTrailer: onOpenTrailer,
                  onLoadMore: onLoadMore,
                  imageHeaders: imageHeaders,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
