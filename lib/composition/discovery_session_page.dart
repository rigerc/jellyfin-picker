import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/network/media_browser_authorization.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/catalog/application/catalog_cubit.dart';
import 'package:jellyfin_picker/features/catalog/data/jellyfin_catalog_repository.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/stored_session.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/features/discovery/application/random_discovery_selector.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_state.dart';
import 'package:jellyfin_picker/features/discovery/domain/serialization/catalog_filter_codec.dart';
import 'package:jellyfin_picker/features/discovery/presentation/discovery_page.dart';
import 'package:jellyfin_picker/features/favorites/application/favorite_cubit.dart';
import 'package:jellyfin_picker/features/favorites/data/jellyfin_favorite_repository.dart';
import 'package:jellyfin_picker/features/persistence/data/shared_preferences_discovery_store.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

final class DiscoverySessionPage extends StatefulWidget {
  const DiscoverySessionPage({
    required this.session,
    required this.client,
    this.onReconnect,
    super.key,
  });

  final StoredSession session;
  final http.Client client;
  final VoidCallback? onReconnect;

  @override
  State<DiscoverySessionPage> createState() => _DiscoverySessionPageState();
}

final class _DiscoverySessionPageState extends State<DiscoverySessionPage> {
  late final CatalogCubit _catalogCubit;
  late final DiscoveryCubit _discoveryCubit;
  late final FavoriteCubit _favoriteCubit;
  StreamSubscription<DiscoveryState>? _discoverySubscription;
  String? _loadedFilterFingerprint;

  @override
  void initState() {
    super.initState();
    final session = widget.session;
    _catalogCubit = CatalogCubit(
      JellyfinCatalogRepository(
        client: widget.client,
        serverUrl: session.serverUrl,
        accessToken: session.accessToken,
        deviceId: session.deviceId,
        userId: session.userId,
      ),
    );
    _discoveryCubit = DiscoveryCubit(
      store: SharedPreferencesDiscoveryStore(
        SharedPreferencesAsyncBlobPreferences(),
      ),
      scopeKey: '${session.serverUrl}/${session.userId}',
      selector: RandomDiscoverySelector(),
    );
    _favoriteCubit = FavoriteCubit(
      JellyfinFavoriteRepository(
        client: widget.client,
        serverUrl: session.serverUrl,
        accessToken: session.accessToken,
        deviceId: session.deviceId,
        userId: session.userId,
      ),
    );
    unawaited(_start());
  }

  Future<void> _start() async {
    await _discoveryCubit.hydrate();
    _discoverySubscription = _discoveryCubit.stream.listen(
      _reloadWhenFilterChanges,
    );
    await _loadCatalog(_discoveryCubit.state);
  }

  void _reloadWhenFilterChanges(DiscoveryState state) {
    final fingerprint = CatalogFilterCodec.encode(state.filter).toString();
    if (fingerprint == _loadedFilterFingerprint) {
      return;
    }
    unawaited(_loadCatalog(state));
  }

  Future<void> _loadCatalog(DiscoveryState state) async {
    _loadedFilterFingerprint = CatalogFilterCodec.encode(
      state.filter,
    ).toString();
    await _catalogCubit.load(filter: state.filter);
  }

  @override
  void dispose() {
    unawaited(_catalogCubit.close());
    unawaited(_discoveryCubit.close());
    unawaited(_favoriteCubit.close());
    unawaited(_discoverySubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return MultiBlocProvider(
      providers: [
        BlocProvider<CatalogCubit>.value(value: _catalogCubit),
        BlocProvider<FavoriteCubit>.value(value: _favoriteCubit),
      ],
      child: BlocConsumer<CatalogCubit, CatalogState>(
        listener: (context, state) {
          if (state case CatalogLoaded(:final candidates)) {
            unawaited(_discoveryCubit.replaceCandidates(candidates));
          }
        },
        builder: (context, state) {
          final loading = switch (state) {
            CatalogLoading() || CatalogLoaded(loadingMore: true) => true,
            _ => false,
          };
          final failedWithoutCandidates = switch (state) {
            CatalogLoaded(candidates: final values, failure: final failure) =>
              values.isEmpty && failure != null,
            _ => false,
          };
          if (failedWithoutCandidates) {
            return _CatalogError(onReconnect: widget.onReconnect ?? _retry);
          }
          if (state is CatalogLoading &&
              _discoveryCubit.state.candidates.isEmpty) {
            return const _CatalogLoading();
          }
          return Stack(
            children: <Widget>[
              DiscoveryPage(
                cubit: _discoveryCubit,
                imageHeaders: <String, String>{
                  'Authorization': MediaBrowserAuthorization.value(
                    deviceId: session.deviceId,
                    token: session.accessToken,
                  ),
                },
                onToggleFavorite: _toggleFavorite,
              ),
              if (loading) const LinearProgressIndicator(),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _toggleFavorite(CatalogCandidate candidate) async {
    final requested = candidate.favorite != true;
    await _favoriteCubit.setFavorite(
      itemId: candidate.id,
      isFavorite: requested,
    );
    final mutation = _favoriteCubit.state.forItem(candidate.id);
    return mutation?.status == FavoriteStatus.succeeded &&
        mutation?.value == requested;
  }

  void _retry() => unawaited(_loadCatalog(_discoveryCubit.state));
}

final class _CatalogLoading extends StatelessWidget {
  const _CatalogLoading();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Semantics(
          liveRegion: true,
          label: AppLocalizations.of(context).catalogLoadingLabel,
          child: const CircularProgressIndicator(),
        ),
      ),
    ),
  );
}

final class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.onReconnect});

  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(CandySpacing.page),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: CandySpacing.compact,
              children: <Widget>[
                const Icon(Icons.cloud_off_outlined),
                Text(
                  localization.catalogErrorTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                Text(
                  localization.catalogErrorDescription,
                  textAlign: TextAlign.center,
                ),
                FilledButton.icon(
                  onPressed: onReconnect,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(localization.catalogReconnectLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
