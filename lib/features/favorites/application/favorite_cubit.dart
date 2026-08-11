import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/features/favorites/domain/failures/favorite_failure.dart';
import 'package:jellyfin_picker/features/favorites/domain/repositories/favorite_repository.dart';

enum FavoriteStatus { pending, succeeded, failed }

final class FavoriteItemMutation {
  const FavoriteItemMutation._({
    required this.status,
    required this.requestedValue,
    this.value,
    this.failure,
  });

  const FavoriteItemMutation.pending({required bool requestedValue})
    : this._(status: FavoriteStatus.pending, requestedValue: requestedValue);

  const FavoriteItemMutation.succeeded({required bool value})
    : this._(
        status: FavoriteStatus.succeeded,
        requestedValue: value,
        value: value,
      );

  const FavoriteItemMutation.failed({
    required bool requestedValue,
    required FavoriteFailure failure,
  }) : this._(
         status: FavoriteStatus.failed,
         requestedValue: requestedValue,
         failure: failure,
       );

  final FavoriteStatus status;
  final bool requestedValue;
  final bool? value;
  final FavoriteFailure? failure;
}

final class FavoriteState {
  FavoriteState({
    Map<String, FavoriteItemMutation> mutations =
        const <String, FavoriteItemMutation>{},
  }) : mutations = Map<String, FavoriteItemMutation>.unmodifiable(mutations);

  final Map<String, FavoriteItemMutation> mutations;

  FavoriteItemMutation? forItem(String itemId) => mutations[itemId];

  FavoriteState withMutation(String itemId, FavoriteItemMutation mutation) =>
      FavoriteState(
        mutations: <String, FavoriteItemMutation>{
          ...mutations,
          itemId: mutation,
        },
      );
}

final class FavoriteCubit extends Cubit<FavoriteState> {
  FavoriteCubit(this.repository) : super(FavoriteState());

  final FavoriteRepository repository;
  final Map<String, int> _generations = <String, int>{};

  Future<void> setFavorite({
    required String itemId,
    required bool isFavorite,
  }) async {
    final normalizedItemId = itemId.trim();
    final generation = (_generations[normalizedItemId] ?? 0) + 1;
    _generations[normalizedItemId] = generation;
    emit(
      state.withMutation(
        normalizedItemId,
        FavoriteItemMutation.pending(requestedValue: isFavorite),
      ),
    );

    final result = await repository.setFavorite(
      itemId: normalizedItemId,
      isFavorite: isFavorite,
    );
    if (isClosed || _generations[normalizedItemId] != generation) {
      return;
    }

    final mutation = switch (result) {
      FavoriteUpdated(:final isFavorite) => FavoriteItemMutation.succeeded(
        value: isFavorite,
      ),
      FavoriteUpdateFailed(:final failure) => FavoriteItemMutation.failed(
        requestedValue: isFavorite,
        failure: failure,
      ),
    };
    emit(state.withMutation(normalizedItemId, mutation));
  }
}
