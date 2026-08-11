import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/connection_request.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/session_summary.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/stored_session.dart';
import 'package:jellyfin_picker/features/connection/domain/failures/connection_failure.dart';
import 'package:jellyfin_picker/features/connection/domain/repositories/connection_repository.dart';

sealed class ConnectionState {
  const ConnectionState();
}

final class ConnectionIdle extends ConnectionState {
  const ConnectionIdle();
}

final class ConnectionSubmitting extends ConnectionState {
  const ConnectionSubmitting();
}

final class ConnectionRestoring extends ConnectionState {
  const ConnectionRestoring();
}

final class ConnectionNeedsPrivateHttpConfirmation extends ConnectionState {
  const ConnectionNeedsPrivateHttpConfirmation(this.serverUrl);

  final String serverUrl;
}

final class ConnectionAuthenticated extends ConnectionState {
  const ConnectionAuthenticated(this.session);

  final StoredSession session;

  SessionSummary get summary => SessionSummary.fromStoredSession(session);
}

final class ConnectionFailureState extends ConnectionState {
  const ConnectionFailureState(this.failure);

  final ConnectionFailure failure;
}

final class ConnectionReauthenticationRequired extends ConnectionState {
  const ConnectionReauthenticationRequired(this.failure);

  final ConnectionFailure failure;
}

final class ConnectionCubit extends Cubit<ConnectionState> {
  ConnectionCubit(this.repository) : super(const ConnectionIdle());

  final ConnectionRepository repository;
  ConnectionRequest? _pendingPrivateHttpRequest;
  int _generation = 0;

  Future<void> submit(ConnectionRequest request) async {
    final generation = ++_generation;
    _pendingPrivateHttpRequest = null;
    if (isClosed) {
      return;
    }
    emit(const ConnectionSubmitting());
    final result = await repository.connect(request);
    if (isClosed || generation != _generation) {
      return;
    }
    _emitConnectionResult(result, request);
  }

  Future<void> confirmPrivateHttp() async {
    final request = _pendingPrivateHttpRequest;
    if (request == null) {
      return;
    }
    final generation = ++_generation;
    if (isClosed) {
      return;
    }
    emit(const ConnectionSubmitting());
    final result = await repository.connect(
      request.copyWith(allowPrivateHttp: true),
    );
    if (isClosed || generation != _generation) {
      return;
    }
    _pendingPrivateHttpRequest = null;
    _emitConnectionResult(result, request);
  }

  Future<void> restore() async {
    final generation = ++_generation;
    _pendingPrivateHttpRequest = null;
    if (isClosed) {
      return;
    }
    emit(const ConnectionRestoring());
    final result = await repository.restoreSession();
    if (isClosed || generation != _generation) {
      return;
    }
    switch (result) {
      case NoStoredSession():
        emit(const ConnectionIdle());
      case SessionRestored(:final session):
        emit(ConnectionAuthenticated(session));
      case SessionRestoreFailure(:final failure):
        if (failure is ExpiredSessionFailure) {
          emit(ConnectionReauthenticationRequired(failure));
        } else {
          emit(ConnectionFailureState(failure));
        }
    }
  }

  Future<void> logout() async {
    final generation = ++_generation;
    _pendingPrivateHttpRequest = null;
    final result = await repository.logout();
    if (isClosed || generation != _generation) {
      return;
    }
    switch (result) {
      case LogoutCompleted():
        emit(const ConnectionIdle());
      case LogoutStorageFailureResult(:final failure):
        emit(ConnectionFailureState(failure));
    }
  }

  void _emitConnectionResult(
    ConnectionResult result,
    ConnectionRequest request,
  ) {
    if (isClosed) {
      return;
    }
    switch (result) {
      case ConnectionSuccess(:final session):
        emit(ConnectionAuthenticated(session));
      case PrivateHttpConfirmationResult(:final serverUrl):
        _pendingPrivateHttpRequest = request;
        emit(ConnectionNeedsPrivateHttpConfirmation(serverUrl));
      case ConnectionFailureResult(:final failure):
        emit(ConnectionFailureState(failure));
    }
  }
}
