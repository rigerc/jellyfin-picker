/// Typed failures returned by the connection boundary.
sealed class ConnectionFailure implements Exception {
  const ConnectionFailure();
}

final class InvalidServerUrlFailure extends ConnectionFailure {
  const InvalidServerUrlFailure();
}

final class PublicHttpFailure extends ConnectionFailure {
  const PublicHttpFailure();
}

final class PrivateHttpConfirmationRequiredFailure extends ConnectionFailure {
  const PrivateHttpConfirmationRequiredFailure();
}

final class UnreachableFailure extends ConnectionFailure {
  const UnreachableFailure();
}

final class ServerFailure extends ConnectionFailure {
  const ServerFailure();
}

final class InvalidCertificateFailure extends ConnectionFailure {
  const InvalidCertificateFailure();
}

final class IncompatibleServerFailure extends ConnectionFailure {
  const IncompatibleServerFailure();
}

final class UnsafeRedirectFailure extends ConnectionFailure {
  const UnsafeRedirectFailure();
}

final class InvalidCredentialsFailure extends ConnectionFailure {
  const InvalidCredentialsFailure();
}

final class ExpiredSessionFailure extends ConnectionFailure {
  const ExpiredSessionFailure();
}

final class StorageFailure extends ConnectionFailure {
  const StorageFailure();
}
