import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:jellyfin_picker/features/connection/data/jellyfin_connection_repository.dart';
import 'package:jellyfin_picker/features/connection/data/session_store.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/connection_request.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/stored_session.dart';
import 'package:jellyfin_picker/features/connection/domain/failures/connection_failure.dart';
import 'package:jellyfin_picker/features/connection/domain/repositories/connection_repository.dart';
import '../../../shared/fake_session_store.dart';
import '../../../shared/recording_http_client.dart';

void main() {
  test(
    'should probe and authenticate with the modern Jellyfin header',
    () async {
      final client = RecordingHttpClient((request) async {
        if (request.url.path.endsWith('/System/Info/Public')) {
          return _jsonResponse({
            'ProductName': 'Jellyfin',
            'Version': '10.9.0',
            'ServerName': 'Candy Server',
          });
        }
        return _jsonResponse({
          'AccessToken': 'access-token',
          'User': <String, Object>{'Id': 'user-id', 'Name': 'alice'},
        });
      });
      final store = FakeSessionStore();
      final repository = JellyfinConnectionRepository(
        client: client,
        sessionStore: store,
        deviceIdProvider: const FakeDeviceIdProvider('device-id'),
      );

      final result = await repository.connect(
        const ConnectionRequest(
          baseUrl: 'https://example.test/jellyfin/',
          username: 'alice',
          password: 'password',
        ),
      );

      expect(result, isA<ConnectionSuccess>());
      expect(store.session?.accessToken, 'access-token');
      expect(store.session?.deviceId, 'device-id');
      expect(client.requests[0].url.path, '/jellyfin/System/Info/Public');
      expect(client.requests[1].url.path, '/jellyfin/Users/AuthenticateByName');
      expect(
        client.requests[1].headers['authorization'],
        contains('MediaBrowser'),
      );
      expect(
        client.requests[1].headers['authorization'],
        contains('DeviceId="device-id"'),
      );
      expect(client.bodies[1], contains('"Pw":"password"'));
    },
  );

  test(
    'should accept the official Jellyfin Server 10.11 product identity',
    () async {
      final repository = _repositoryWithResponses(<http.Response>[
        _jsonResponse({
          'ProductName': 'Jellyfin Server',
          'Version': '10.11.11',
        }),
        _jsonResponse({
          'AccessToken': 'access-token',
          'User': <String, Object>{'Id': 'user-id', 'Name': 'alice'},
        }),
      ]);

      final result = await repository.connect(_request());

      expect(result, isA<ConnectionSuccess>());
    },
  );

  test('should reject incompatible servers after the public probe', () async {
    final repository = _repositoryWithResponses(<http.Response>[
      _jsonResponse({'ProductName': 'Plex', 'Version': '10.11.11'}),
    ]);

    final result = await repository.connect(_request());

    expect(result, isA<ConnectionFailureResult>());
    expect(
      (result as ConnectionFailureResult).failure,
      isA<IncompatibleServerFailure>(),
    );
  });

  test('should reject unsupported Jellyfin server versions', () async {
    final repository = _repositoryWithResponses(<http.Response>[
      _jsonResponse({'ProductName': 'Jellyfin Server', 'Version': '9.0.0'}),
    ]);

    final result = await repository.connect(_request());

    expect(
      (result as ConnectionFailureResult).failure,
      isA<IncompatibleServerFailure>(),
    );
  });

  test('should reject malformed Jellyfin server versions', () async {
    final repository = _repositoryWithResponses(<http.Response>[
      _jsonResponse({'ProductName': 'Jellyfin Server', 'Version': 'ten'}),
    ]);

    final result = await repository.connect(_request());

    expect(
      (result as ConnectionFailureResult).failure,
      isA<IncompatibleServerFailure>(),
    );
  });

  test(
    'should report invalid credentials when authentication is unauthorized',
    () async {
      final repository = _repositoryWithResponses(<http.Response>[
        _jsonResponse({'ProductName': 'Jellyfin', 'Version': '10.9.0'}),
        http.Response('', 401),
      ]);

      final result = await repository.connect(_request());

      expect(result, isA<ConnectionFailureResult>());
      expect(
        (result as ConnectionFailureResult).failure,
        isA<InvalidCredentialsFailure>(),
      );
    },
  );

  test(
    'should report unreachable servers when the client cannot connect',
    () async {
      final client = RecordingHttpClient((request) async {
        throw const SocketException('offline');
      });
      final repository = JellyfinConnectionRepository(
        client: client,
        sessionStore: FakeSessionStore(),
        deviceIdProvider: const FakeDeviceIdProvider('device-id'),
      );

      final result = await repository.connect(_request());

      expect(result, isA<ConnectionFailureResult>());
      expect(
        (result as ConnectionFailureResult).failure,
        isA<UnreachableFailure>(),
      );
    },
  );

  test(
    'should map unauthorized public probes to incompatible server',
    () async {
      final repository = _repositoryWithResponses(<http.Response>[
        http.Response('', 401),
      ]);

      final result = await repository.connect(_request());

      expect(result, isA<ConnectionFailureResult>());
      expect(
        (result as ConnectionFailureResult).failure,
        isA<IncompatibleServerFailure>(),
      );
    },
  );

  test('should reject redirects without following them', () async {
    final repository = _repositoryWithResponses(<http.Response>[
      http.Response(
        '',
        302,
        headers: <String, String>{'location': 'https://evil.test'},
      ),
    ]);

    final result = await repository.connect(_request());

    expect(result, isA<ConnectionFailureResult>());
    expect(
      (result as ConnectionFailureResult).failure,
      isA<UnsafeRedirectFailure>(),
    );
  });

  test('should reject invalid TLS certificates without a bypass', () async {
    final client = RecordingHttpClient((request) async {
      throw const HandshakeException('certificate invalid');
    });
    final repository = JellyfinConnectionRepository(
      client: client,
      sessionStore: FakeSessionStore(),
      deviceIdProvider: const FakeDeviceIdProvider('device-id'),
    );

    final result = await repository.connect(_request());

    expect(result, isA<ConnectionFailureResult>());
    expect(
      (result as ConnectionFailureResult).failure,
      isA<InvalidCertificateFailure>(),
    );
  });

  test(
    'should clear local state after unauthorized restore and attempt remote logout',
    () async {
      final store = FakeSessionStore(
        session: const StoredSession(
          serverUrl: 'https://example.test',
          accessToken: 'expired-token',
          userId: 'user-id',
          username: 'alice',
          deviceId: 'device-id',
        ),
      );
      final client = RecordingHttpClient((request) async {
        if (request.url.path.endsWith('/System/Info')) {
          return http.Response('', 401);
        }
        return http.Response('', 204);
      });
      final repository = JellyfinConnectionRepository(
        client: client,
        sessionStore: store,
        deviceIdProvider: const FakeDeviceIdProvider('device-id'),
      );

      final result = await repository.restoreSession();

      expect(result, isA<SessionRestoreFailure>());
      expect(
        (result as SessionRestoreFailure).failure,
        isA<ExpiredSessionFailure>(),
      );
      expect(store.session, isNull);
      expect(
        client.requests.any(
          (request) => request.url.path.endsWith('/Sessions/Logout'),
        ),
        isTrue,
      );
    },
  );

  test(
    'should return no stored session when secure storage is empty',
    () async {
      final repository = _repositoryWithResponses(<http.Response>[]);

      final result = await repository.restoreSession();

      expect(result, isA<NoStoredSession>());
    },
  );

  test('should restore a session when the token validates', () async {
    final store = FakeSessionStore(session: _storedSession());
    final repository = JellyfinConnectionRepository(
      client: RecordingHttpClient(
        (request) async =>
            _jsonResponse({'ProductName': 'Jellyfin', 'Version': '10.9.0'}),
      ),
      sessionStore: store,
      deviceIdProvider: const FakeDeviceIdProvider('device-id'),
    );

    final result = await repository.restoreSession();

    expect(result, isA<SessionRestored>());
  });

  test('should clear local state when remote logout is unreachable', () async {
    final store = FakeSessionStore(session: _storedSession());
    final repository = JellyfinConnectionRepository(
      client: RecordingHttpClient((request) async {
        throw const SocketException('offline');
      }),
      sessionStore: store,
      deviceIdProvider: const FakeDeviceIdProvider('device-id'),
    );

    final result = await repository.logout();

    expect((result as LogoutCompleted).remoteSucceeded, isFalse);
    expect(store.session, isNull);
  });

  test(
    'should return a typed storage failure when logout cannot clear state',
    () async {
      final repository = JellyfinConnectionRepository(
        client: RecordingHttpClient((request) async => http.Response('', 204)),
        sessionStore: FailingClearSessionStore(session: _storedSession()),
        deviceIdProvider: const FakeDeviceIdProvider('device-id'),
      );

      final result = await repository.logout();

      expect(result, isA<LogoutStorageFailureResult>());
    },
  );

  test(
    'should clear local state when session reading fails during logout',
    () async {
      final store = FailingReadSessionStore();
      final repository = JellyfinConnectionRepository(
        client: RecordingHttpClient((request) async => http.Response('', 204)),
        sessionStore: store,
        deviceIdProvider: const FakeDeviceIdProvider('device-id'),
      );

      final result = await repository.logout();

      expect(result, isA<LogoutStorageFailureResult>());
      expect(store.clearCalled, isTrue);
    },
  );

  test(
    'should return storage failure when expired-session clearing fails',
    () async {
      final repository = JellyfinConnectionRepository(
        client: RecordingHttpClient((request) async {
          if (request.url.path.endsWith('/System/Info')) {
            return http.Response('', 401);
          }
          return http.Response('', 204);
        }),
        sessionStore: FailingClearSessionStore(session: _storedSession()),
        deviceIdProvider: const FakeDeviceIdProvider('device-id'),
      );

      final result = await repository.restoreSession();

      expect(result, isA<SessionRestoreFailure>());
      expect((result as SessionRestoreFailure).failure, isA<StorageFailure>());
    },
  );

  test('should classify transient server errors as a server failure', () async {
    final repository = _repositoryWithResponses(<http.Response>[
      http.Response('', 503),
    ]);

    final result = await repository.connect(_request());

    expect(result, isA<ConnectionFailureResult>());
    expect((result as ConnectionFailureResult).failure, isA<ServerFailure>());
  });

  test(
    'should classify transient authentication errors as a server failure',
    () async {
      final repository = _repositoryWithResponses(<http.Response>[
        _jsonResponse({'ProductName': 'Jellyfin', 'Version': '10.9.0'}),
        http.Response('', 503),
      ]);

      final result = await repository.connect(_request());

      expect(result, isA<ConnectionFailureResult>());
      expect((result as ConnectionFailureResult).failure, isA<ServerFailure>());
    },
  );

  test(
    'should classify transient restore errors as a server failure',
    () async {
      final repository = JellyfinConnectionRepository(
        client: RecordingHttpClient((request) async => http.Response('', 503)),
        sessionStore: FakeSessionStore(session: _storedSession()),
        deviceIdProvider: const FakeDeviceIdProvider('device-id'),
      );

      final result = await repository.restoreSession();

      expect(result, isA<SessionRestoreFailure>());
      expect((result as SessionRestoreFailure).failure, isA<ServerFailure>());
    },
  );

  test('should send redirect-disabled requests for authentication', () async {
    final client = RecordingHttpClient((request) async {
      if (request.url.path.endsWith('/System/Info/Public')) {
        return _jsonResponse({'ProductName': 'Jellyfin', 'Version': '10.9.0'});
      }
      return _jsonResponse({
        'AccessToken': 'token',
        'User': <String, Object>{'Id': 'id', 'Name': 'alice'},
      });
    });
    final repository = JellyfinConnectionRepository(
      client: client,
      sessionStore: FakeSessionStore(),
      deviceIdProvider: const FakeDeviceIdProvider('device-id'),
    );

    await repository.connect(_request());

    expect(
      client.requests,
      everyElement(
        predicate<http.BaseRequest>(
          (request) => request.followRedirects == false,
        ),
      ),
    );
  });
}

ConnectionRequest _request() {
  return const ConnectionRequest(
    baseUrl: 'https://example.test',
    username: 'alice',
    password: 'password',
  );
}

JellyfinConnectionRepository _repositoryWithResponses(
  List<http.Response> responses,
) {
  final queue = Queue<http.Response>.from(responses);
  return JellyfinConnectionRepository(
    client: RecordingHttpClient((request) async => queue.removeFirst()),
    sessionStore: FakeSessionStore(),
    deviceIdProvider: const FakeDeviceIdProvider('device-id'),
  );
}

http.Response _jsonResponse(Map<String, Object> body) {
  return http.Response(
    jsonEncode(body),
    200,
    headers: <String, String>{'content-type': 'application/json'},
  );
}

StoredSession _storedSession() {
  return const StoredSession(
    serverUrl: 'https://example.test',
    accessToken: 'token',
    userId: 'user-id',
    username: 'alice',
    deviceId: 'device-id',
  );
}

final class FailingClearSessionStore implements SessionStore {
  FailingClearSessionStore({this.session});

  StoredSession? session;

  @override
  Future<void> clearSession() async {
    throw StateError('storage unavailable');
  }

  @override
  Future<StoredSession?> readSession() async => session;

  @override
  Future<void> writeSession(StoredSession value) async => session = value;
}

final class FailingReadSessionStore implements SessionStore {
  bool clearCalled = false;

  @override
  Future<void> clearSession() async => clearCalled = true;

  @override
  Future<StoredSession?> readSession() async {
    throw StateError('storage unavailable');
  }

  @override
  Future<void> writeSession(StoredSession value) async {}
}
