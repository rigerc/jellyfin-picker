import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/keys/widget_keys.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/discovery/presentation/discovery_page.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_details_metadata.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

Future<void> showDiscoveryDetails(
  BuildContext context,
  CatalogCandidate candidate, {
  CandidateDetailsLoader? onLoadDetails,
  TrailerLauncher? onOpenTrailer,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * 0.9,
  ),
  showDragHandle: true,
  builder: (context) => DiscoveryDetailsSheet(
    candidate: candidate,
    onLoadDetails: onLoadDetails,
    onOpenTrailer: onOpenTrailer,
  ),
);

final class DiscoveryDetailsSheet extends StatefulWidget {
  const DiscoveryDetailsSheet({
    required this.candidate,
    this.onLoadDetails,
    this.onOpenTrailer,
    super.key,
  });

  final CatalogCandidate candidate;
  final CandidateDetailsLoader? onLoadDetails;
  final TrailerLauncher? onOpenTrailer;

  @override
  State<DiscoveryDetailsSheet> createState() => _DiscoveryDetailsSheetState();
}

final class _DiscoveryDetailsSheetState extends State<DiscoveryDetailsSheet> {
  late final Future<CatalogCandidate?>? _details;

  @override
  void initState() {
    super.initState();
    _details = widget.onLoadDetails?.call(widget.candidate);
  }

  @override
  Widget build(BuildContext context) {
    final details = _details;
    if (details == null) {
      return _DiscoveryDetailsContent(
        candidate: widget.candidate,
        onOpenTrailer: widget.onOpenTrailer,
      );
    }
    return FutureBuilder<CatalogCandidate?>(
      future: details,
      builder: (context, snapshot) => Stack(
        children: <Widget>[
          _DiscoveryDetailsContent(
            candidate: snapshot.data ?? widget.candidate,
            onOpenTrailer: widget.onOpenTrailer,
          ),
          if (snapshot.connectionState != ConnectionState.done)
            const LinearProgressIndicator(
              key: WidgetKeys.discoveryDetailsLoading,
            ),
        ],
      ),
    );
  }
}

final class _DiscoveryDetailsContent extends StatelessWidget {
  const _DiscoveryDetailsContent({
    required this.candidate,
    required this.onOpenTrailer,
  });

  final CatalogCandidate candidate;
  final TrailerLauncher? onOpenTrailer;

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
          if (candidate.trailers.isNotEmpty) ...<Widget>[
            const SizedBox(height: CandySpacing.cardGap),
            _TrailerList(
              trailers: candidate.trailers,
              onOpenTrailer: onOpenTrailer,
            ),
          ],
        ],
      ),
    );
  }
}

final class _TrailerList extends StatelessWidget {
  const _TrailerList({required this.trailers, required this.onOpenTrailer});

  final List<CatalogTrailer> trailers;
  final TrailerLauncher? onOpenTrailer;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CandySpacing.compact,
      children: <Widget>[
        Text(
          localization.discoveryTrailersLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final (index, trailer) in trailers.indexed)
          OutlinedButton.icon(
            key: WidgetKeys.discoveryTrailer(index),
            onPressed: onOpenTrailer == null
                ? null
                : () => _openTrailer(context, trailer.uri),
            icon: const Icon(Icons.play_circle_outline_rounded),
            label: Text(_trailerLabel(localization, trailer)),
          ),
      ],
    );
  }

  Future<void> _openTrailer(BuildContext context, Uri uri) async {
    final succeeded = await onOpenTrailer?.call(uri) ?? false;
    if (!succeeded && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).discoveryTrailerLaunchError,
          ),
        ),
      );
    }
  }

  String _trailerLabel(AppLocalizations localization, CatalogTrailer trailer) {
    final name = trailer.name?.trim();
    return name == null || name.isEmpty
        ? localization.discoveryPlayTrailerLabel
        : name;
  }
}
