sealed class FavoriteFailure {
  const FavoriteFailure();
}

final class InvalidFavoriteRequestFailure extends FavoriteFailure {
  const InvalidFavoriteRequestFailure();
}

final class InvalidFavoriteConfigurationFailure extends FavoriteFailure {
  const InvalidFavoriteConfigurationFailure();
}

final class ExpiredFavoriteSessionFailure extends FavoriteFailure {
  const ExpiredFavoriteSessionFailure();
}

final class UnauthorizedFavoriteFailure extends FavoriteFailure {
  const UnauthorizedFavoriteFailure();
}

final class FavoriteItemNotFoundFailure extends FavoriteFailure {
  const FavoriteItemNotFoundFailure();
}

final class FavoriteServerFailure extends FavoriteFailure {
  const FavoriteServerFailure();
}

final class InvalidCertificateFavoriteFailure extends FavoriteFailure {
  const InvalidCertificateFavoriteFailure();
}

final class UnreachableFavoriteFailure extends FavoriteFailure {
  const UnreachableFavoriteFailure();
}

final class UnsafeFavoriteRedirectFailure extends FavoriteFailure {
  const UnsafeFavoriteRedirectFailure();
}

final class IncompatibleFavoriteResponseFailure extends FavoriteFailure {
  const IncompatibleFavoriteResponseFailure();
}
