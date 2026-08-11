import 'package:jellyfin_picker/features/connection/domain/entities/connection_request.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/stored_session.dart';
import 'package:jellyfin_picker/features/connection/domain/failures/connection_failure.dart';

sealed class ConnectionResult {
  const ConnectionResult();
}

final class ConnectionSuccess extends ConnectionResult {
  const ConnectionSuccess(this.session);

  final StoredSession session;
}

final class ConnectionFailureResult extends ConnectionResult {
  const ConnectionFailureResult(this.failure);

  final ConnectionFailure failure;
}

final class PrivateHttpConfirmationResult extends ConnectionResult {
  const PrivateHttpConfirmationResult(this.serverUrl);

  final String serverUrl;
}

sealed class SessionRestoreResult {
  const SessionRestoreResult();
}

final class NoStoredSession extends SessionRestoreResult {
  const NoStoredSession();
}

final class SessionRestored extends SessionRestoreResult {
  const SessionRestored(this.session);

  final StoredSession session;
}

final class SessionRestoreFailure extends SessionRestoreResult {
  const SessionRestoreFailure(this.failure);

  final ConnectionFailure failure;
}

sealed class LogoutResult {
  const LogoutResult();
}

final class LogoutCompleted extends LogoutResult {
  const LogoutCompleted({required this.remoteSucceeded});

  final bool remoteSucceeded;
}

final class LogoutStorageFailureResult extends LogoutResult {
  const LogoutStorageFailureResult(this.failure);

  final StorageFailure failure;
}

abstract interface class ConnectionRepository {
  Future<ConnectionResult> connect(ConnectionRequest request);

  Future<SessionRestoreResult> restoreSession();

  Future<LogoutResult> logout();
}
