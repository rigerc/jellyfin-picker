import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_details_metadata.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

Future<void> showDiscoveryDetails(
  BuildContext context,
  CatalogCandidate candidate,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * 0.9,
  ),
  showDragHandle: true,
  builder: (context) => DiscoveryDetailsSheet(candidate: candidate),
);

final class DiscoveryDetailsSheet extends StatelessWidget {
  const DiscoveryDetailsSheet({required this.candidate, super.key});

  final CatalogCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final unknown = localization.discoveryUnknownValue;
    return SafeArea(
      child: ListView(
        key: WidgetKeys.discoveryDetails,
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
          CandySpacing.page,
          CandySpacing.page,
          CandySpacing.page,
          CandySpacing.compact,
        ),
        children: <Widget>[
          Text(
            candidate.name,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: CandySpacing.cardGap),
          Text(localization.discoverySynopsisLabel),
          Text(candidate.overview ?? unknown),
          const SizedBox(height: CandySpacing.cardGap),
          DiscoveryDetailsMetadata(candidate: candidate),
        ],
      ),
    );
  }
}
