import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/connection_request.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/session_summary.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/stored_session.dart';
import 'package:jellyfin_picker/features/connection/domain/failures/connection_failure.dart';
import 'package:jellyfin_picker/features/connection/domain/repositories/connection_repository.dart';
import 'package:jellyfin_picker/features/connection/presentation/connection_cubit.dart';
import '../../../shared/fake_connection_repository.dart';

void main() {
  test(
    'should expose private HTTP confirmation when the repository requests it',
    () async {
      final cubit = ConnectionCubit(
        FakeConnectionRepository(
          result: const PrivateHttpConfirmationResult(
            'http://192.168.1.20:8096',
          ),
        ),
      );

      await cubit.submit(_request());

      expect(cubit.state, isA<ConnectionNeedsPrivateHttpConfirmation>());
    },
  );

  test(
    'should expose contextual reauthentication when restore finds an expired token',
    () async {
      final cubit = ConnectionCubit(
        FakeConnectionRepository(
          restoreResult: const SessionRestoreFailure(ExpiredSessionFailure()),
        ),
      );

      await cubit.restore();

      expect(cubit.state, isA<ConnectionReauthenticationRequired>());
    },
  );

  test(
    'should expose authenticated state when credentials are accepted',
    () async {
      final cubit = ConnectionCubit(
        FakeConnectionRepository(result: ConnectionSuccess(_session())),
      );

      await cubit.submit(_request());

      expect(cubit.state, isA<ConnectionAuthenticated>());
      expect(
        (cubit.state as ConnectionAuthenticated).summary,
        isA<SessionSummary>(),
      );
    },
  );

  test('should ignore a late restore result after logout starts', () async {
    final repository = RaceConnectionRepository();
    final cubit = ConnectionCubit(repository);
    final restore = cubit.restore();
    await repository.restoreStarted.future;
    final logout = cubit.logout();
    repository.completeRestore(SessionRestored(_session()));
    await restore;
    repository.completeLogout();
    await logout;

    expect(cubit.state, isA<ConnectionIdle>());
  });

  test('should return to idle when restore finds no saved session', () async {
    final cubit = ConnectionCubit(FakeConnectionRepository());

    await cubit.restore();

    expect(cubit.state, isA<ConnectionIdle>());
  });

  test(
    'should expose authenticated state when restore validates a token',
    () async {
      final cubit = ConnectionCubit(
        FakeConnectionRepository(restoreResult: SessionRestored(_session())),
      );

      await cubit.restore();

      expect(cubit.state, isA<ConnectionAuthenticated>());
    },
  );

  test(
    'should expose a failure when restore returns a non-expired error',
    () async {
      final cubit = ConnectionCubit(
        FakeConnectionRepository(
          restoreResult: const SessionRestoreFailure(
            IncompatibleServerFailure(),
          ),
        ),
      );

      await cubit.restore();

      expect(cubit.state, isA<ConnectionFailureState>());
    },
  );

  test('should return to idle when logout completes', () async {
    final cubit = ConnectionCubit(FakeConnectionRepository());
    await cubit.submit(_request());

    await cubit.logout();

    expect(cubit.state, isA<ConnectionIdle>());
  });

  test(
    'should show storage recovery when logout cannot clear local state',
    () async {
      final cubit = ConnectionCubit(
        FakeConnectionRepository(
          logoutResult: const LogoutStorageFailureResult(StorageFailure()),
        ),
      );

      await cubit.logout();

      expect(cubit.state, isA<ConnectionFailureState>());
    },
  );

  test(
    'should clear pending credentials when restore supersedes confirmation',
    () async {
      final repository = FakeConnectionRepository(
        result: const PrivateHttpConfirmationResult('http://192.168.1.20:8096'),
      );
      final cubit = ConnectionCubit(repository);

      await cubit.submit(_request());
      await cubit.restore();
      await cubit.confirmPrivateHttp();

      expect(cubit.state, isA<ConnectionIdle>());
      expect(repository.connectCalls, 1);
    },
  );

  test(
    'should clear pending credentials when logout supersedes confirmation',
    () async {
      final repository = FakeConnectionRepository(
        result: const PrivateHttpConfirmationResult('http://192.168.1.20:8096'),
      );
      final cubit = ConnectionCubit(repository);

      await cubit.submit(_request());
      await cubit.logout();
      await cubit.confirmPrivateHttp();

      expect(cubit.state, isA<ConnectionIdle>());
      expect(repository.connectCalls, 1);
    },
  );
}

ConnectionRequest _request() {
  return const ConnectionRequest(
    baseUrl: 'http://192.168.1.20:8096',
    username: 'alice',
    password: 'password',
  );
}

StoredSession _session() {
  return const StoredSession(
    serverUrl: 'https://example.test',
    accessToken: 'token',
    userId: 'user-id',
    username: 'alice',
    deviceId: 'device-id',
  );
}

final class RaceConnectionRepository implements ConnectionRepository {
  final restoreStarted = Completer<void>();
  final logoutStarted = Completer<void>();
  late final Completer<SessionRestoreResult> _restore;
  late final Completer<LogoutResult> _logout;

  @override
  Future<ConnectionResult> connect(ConnectionRequest request) async =>
      ConnectionSuccess(_session());

  @override
  Future<SessionRestoreResult> restoreSession() {
    _restore = Completer<SessionRestoreResult>();
    restoreStarted.complete();
    return _restore.future;
  }

  @override
  Future<LogoutResult> logout() {
    _logout = Completer<LogoutResult>();
    logoutStarted.complete();
    return _logout.future;
  }

  void completeRestore(SessionRestoreResult result) =>
      _restore.complete(result);

  void completeLogout() =>
      _logout.complete(const LogoutCompleted(remoteSucceeded: true));
}
