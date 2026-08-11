import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/features/favorites/application/favorite_cubit.dart';
import 'package:jellyfin_picker/features/favorites/domain/failures/favorite_failure.dart';
import 'package:jellyfin_picker/features/favorites/domain/repositories/favorite_repository.dart';

import '../../../shared/favorite_repository_fake.dart';

void main() {
  group('FavoriteCubit', () {
    test('should expose pending then success for an item', () async {
      final repository = FavoriteRepositoryFake();
      final cubit = FavoriteCubit(repository);

      final update = cubit.setFavorite(itemId: 'movie-1', isFavorite: true);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.forItem('movie-1')?.status, FavoriteStatus.pending);
      expect(cubit.state.forItem('movie-1')?.requestedValue, isTrue);

      repository.completions.single.complete(
        const FavoriteUpdated(itemId: 'movie-1', isFavorite: true),
      );
      await update;

      expect(cubit.state.forItem('movie-1')?.status, FavoriteStatus.succeeded);
      expect(cubit.state.forItem('movie-1')?.value, isTrue);
      await cubit.close();
    });

    test('should expose a typed failure for an item', () async {
      final repository = FavoriteRepositoryFake();
      final cubit = FavoriteCubit(repository);

      final update = cubit.setFavorite(itemId: 'movie-1', isFavorite: false);
      repository.completions.single.complete(
        const FavoriteUpdateFailed(UnreachableFavoriteFailure()),
      );
      await update;

      final mutation = cubit.state.forItem('movie-1');
      expect(mutation?.status, FavoriteStatus.failed);
      expect(mutation?.failure, isA<UnreachableFavoriteFailure>());
      expect(mutation?.requestedValue, isFalse);
      await cubit.close();
    });

    test('should track pending mutations independently by item', () async {
      final repository = FavoriteRepositoryFake();
      final cubit = FavoriteCubit(repository);

      final first = cubit.setFavorite(itemId: 'movie-1', isFavorite: true);
      final second = cubit.setFavorite(itemId: 'movie-2', isFavorite: false);

      expect(cubit.state.forItem('movie-1')?.status, FavoriteStatus.pending);
      expect(cubit.state.forItem('movie-2')?.status, FavoriteStatus.pending);

      repository.completions[0].complete(
        const FavoriteUpdated(itemId: 'movie-1', isFavorite: true),
      );
      repository.completions[1].complete(
        const FavoriteUpdated(itemId: 'movie-2', isFavorite: false),
      );
      await Future.wait(<Future<void>>[first, second]);
      await cubit.close();
    });

    test('should ignore a stale completion for the same item', () async {
      final repository = FavoriteRepositoryFake();
      final cubit = FavoriteCubit(repository);

      final first = cubit.setFavorite(itemId: 'movie-1', isFavorite: true);
      final second = cubit.setFavorite(itemId: 'movie-1', isFavorite: false);
      repository.completions[1].complete(
        const FavoriteUpdated(itemId: 'movie-1', isFavorite: false),
      );
      await second;
      repository.completions[0].complete(
        const FavoriteUpdated(itemId: 'movie-1', isFavorite: true),
      );
      await first;

      expect(cubit.state.forItem('movie-1')?.status, FavoriteStatus.succeeded);
      expect(cubit.state.forItem('movie-1')?.value, isFalse);
      await cubit.close();
    });

    test('should forward normalized item id and requested value', () async {
      final repository = FavoriteRepositoryFake();
      final cubit = FavoriteCubit(repository);

      final update = cubit.setFavorite(itemId: ' movie-1 ', isFavorite: true);
      repository.completions.single.complete(
        const FavoriteUpdated(itemId: 'movie-1', isFavorite: true),
      );
      await update;

      expect(repository.invocations.single.itemId, 'movie-1');
      expect(repository.invocations.single.isFavorite, isTrue);
      await cubit.close();
    });
  });
}
