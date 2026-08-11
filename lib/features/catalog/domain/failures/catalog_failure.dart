sealed class CatalogFailure implements Exception {
  const CatalogFailure();
}

final class UnauthorizedCatalogFailure extends CatalogFailure {
  const UnauthorizedCatalogFailure();
}

final class ExpiredCatalogFailure extends CatalogFailure {
  const ExpiredCatalogFailure();
}

final class ServerCatalogFailure extends CatalogFailure {
  const ServerCatalogFailure();
}

final class UnreachableCatalogFailure extends CatalogFailure {
  const UnreachableCatalogFailure();
}

final class InvalidCertificateCatalogFailure extends CatalogFailure {
  const InvalidCertificateCatalogFailure();
}

final class RedirectCatalogFailure extends CatalogFailure {
  const RedirectCatalogFailure();
}

final class IncompatibleCatalogFailure extends CatalogFailure {
  const IncompatibleCatalogFailure();
}

final class NoAccessibleLibraryFailure extends CatalogFailure {
  const NoAccessibleLibraryFailure();
}

final class NoCatalogMatchFailure extends CatalogFailure {
  const NoCatalogMatchFailure();
}

final class PartialCatalogFailure extends CatalogFailure {
  const PartialCatalogFailure();
}

final class MissingMetadataCatalogFailure extends CatalogFailure {
  const MissingMetadataCatalogFailure();
}
