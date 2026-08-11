import 'package:jellyfin_picker/features/favorites/domain/failures/favorite_failure.dart';

sealed class FavoriteUpdateResult {
  const FavoriteUpdateResult();
}

final class FavoriteUpdated extends FavoriteUpdateResult {
  const FavoriteUpdated({required this.itemId, required this.isFavorite});

  final String itemId;
  final bool isFavorite;
}

final class FavoriteUpdateFailed extends FavoriteUpdateResult {
  const FavoriteUpdateFailed(this.failure);

  final FavoriteFailure failure;
}

abstract interface class FavoriteRepository {
  Future<FavoriteUpdateResult> setFavorite({
    required String itemId,
    required bool isFavorite,
  });
}
