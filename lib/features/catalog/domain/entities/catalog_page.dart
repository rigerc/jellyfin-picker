import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/features/catalog/domain/failures/catalog_failure.dart';

final class CatalogPage {
  const CatalogPage({
    required this.candidates,
    required this.hasMore,
    required this.nextIndex,
    required this.total,
    this.failure,
  });

  final List<CatalogCandidate> candidates;
  final bool hasMore;
  final int nextIndex;
  final int total;
  final CatalogFailure? failure;
}
