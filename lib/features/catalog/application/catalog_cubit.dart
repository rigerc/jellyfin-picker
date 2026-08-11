import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/catalog/domain/failures/catalog_failure.dart';
import 'package:jellyfin_picker/features/catalog/domain/repositories/catalog_repository.dart';

sealed class CatalogState {
  const CatalogState();
}

final class CatalogIdle extends CatalogState {
  const CatalogIdle();
}

final class CatalogLoading extends CatalogState {
  const CatalogLoading();
}

final class CatalogLoaded extends CatalogState {
  const CatalogLoaded({
    required this.candidates,
    required this.hasMore,
    required this.nextIndex,
    required this.total,
    this.failure,
    this.loadingMore = false,
  });

  final List<CatalogCandidate> candidates;
  final bool hasMore;
  final int nextIndex;
  final int total;
  final CatalogFailure? failure;
  final bool loadingMore;
}

final class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this.repository) : super(const CatalogIdle());

  final CatalogRepository repository;
  int _generation = 0;

  Future<void> load({CatalogFilter filter = const CatalogFilter()}) async {
    final generation = ++_generation;
    if (isClosed) {
      return;
    }
    emit(const CatalogLoading());
    final candidates = <CatalogCandidate>[];
    final seenIds = <String>{};
    await for (final page in repository.streamPages(filter: filter)) {
      if (isClosed || generation != _generation) {
        return;
      }
      for (final candidate in page.candidates) {
        if (seenIds.add(candidate.id)) {
          candidates.add(candidate);
        }
      }
      emit(
        CatalogLoaded(
          candidates: List<CatalogCandidate>.unmodifiable(candidates),
          hasMore: page.hasMore,
          nextIndex: page.nextIndex,
          total: page.total,
          failure: page.failure,
          loadingMore: page.hasMore,
        ),
      );
    }
  }
}
