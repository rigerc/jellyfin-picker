import 'package:jellyfin_picker/features/connection/domain/entities/connection_request.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/stored_session.dart';
import 'package:jellyfin_picker/features/connection/domain/repositories/connection_repository.dart';

final class FakeConnectionRepository implements ConnectionRepository {
  FakeConnectionRepository({
    this.result = const ConnectionSuccess(
      StoredSession(
        serverUrl: 'https://example.test',
        accessToken: 'token',
        userId: 'user-id',
        username: 'alice',
        deviceId: 'device-id',
      ),
    ),
    this.restoreResult = const NoStoredSession(),
    this.logoutResult = const LogoutCompleted(remoteSucceeded: true),
  });

  final ConnectionResult result;
  final SessionRestoreResult restoreResult;
  final LogoutResult logoutResult;
  int connectCalls = 0;

  @override
  Future<ConnectionResult> connect(ConnectionRequest request) async {
    connectCalls++;
    return result;
  }

  @override
  Future<SessionRestoreResult> restoreSession() async => restoreResult;

  @override
  Future<LogoutResult> logout() async => logoutResult;
}
