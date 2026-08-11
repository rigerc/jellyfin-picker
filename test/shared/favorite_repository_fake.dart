import 'dart:async';

import 'package:jellyfin_picker/features/favorites/domain/repositories/favorite_repository.dart';

final class FavoriteRepositoryInvocation {
  const FavoriteRepositoryInvocation({
    required this.itemId,
    required this.isFavorite,
  });

  final String itemId;
  final bool isFavorite;
}

final class FavoriteRepositoryFake implements FavoriteRepository {
  final List<FavoriteRepositoryInvocation> invocations =
      <FavoriteRepositoryInvocation>[];
  final List<Completer<FavoriteUpdateResult>> completions =
      <Completer<FavoriteUpdateResult>>[];

  @override
  Future<FavoriteUpdateResult> setFavorite({
    required String itemId,
    required bool isFavorite,
  }) {
    invocations.add(
      FavoriteRepositoryInvocation(itemId: itemId, isFavorite: isFavorite),
    );
    final completion = Completer<FavoriteUpdateResult>();
    completions.add(completion);
    return completion.future;
  }
}
