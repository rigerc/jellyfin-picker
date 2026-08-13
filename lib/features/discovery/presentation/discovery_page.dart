import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/discovery/application/discovery_cubit.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_clear_dialog.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_controls.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_mode_switcher.dart';

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
    return Scaffold(
      key: WidgetKeys.discoveryPage,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CandySpacing.page),
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              spacing: CandySpacing.cardGap,
              children: <Widget>[
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight / 2,
                  ),
                  child: DiscoveryControls(
                    onClear: () => confirmClearDiscovery(context),
                  ),
                ),
                Expanded(
                  child: DiscoveryModeSwitcher(
                    onToggleFavorite: onToggleFavorite,
                    imageHeaders: imageHeaders,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
