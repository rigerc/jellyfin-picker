import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/features/connection/data/flutter_secure_session_store.dart';
import 'package:jellyfin_picker/features/connection/data/session_store.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/stored_session.dart';

void main() {
  test('should persist only the documented session keys', () async {
    final store = RecordingKeyValueStore();
    final sessionStore = FlutterSecureSessionStore(store);

    await sessionStore.writeSession(_session());

    expect(
      store.writes.keys,
      containsAll(<String>[
        'connection.server_url',
        'connection.access_token',
        'connection.user_id',
        'connection.username',
        'connection.device_id',
      ]),
    );
    expect(store.writes.keys, isNot(contains('connection.password')));
  });

  test(
    'should best effort delete every session key except device identity',
    () async {
      final store = RecordingKeyValueStore();
      final sessionStore = FlutterSecureSessionStore(store);

      await sessionStore.clearSession();

      expect(
        store.deletes,
        containsAll(<String>[
          'connection.server_url',
          'connection.access_token',
          'connection.user_id',
          'connection.username',
          'connection.server_name',
          'connection.server_version',
        ]),
      );
      expect(store.deletes, isNot(contains('connection.device_id')));
    },
  );

  test('should round trip required and optional session metadata', () async {
    final store = RecordingKeyValueStore();
    final sessionStore = FlutterSecureSessionStore(store);
    const expected = StoredSession(
      serverUrl: 'https://example.test/base',
      accessToken: 'token',
      userId: 'id',
      username: 'alice',
      deviceId: 'device',
      serverName: 'Candy Server',
      serverVersion: '10.9.0',
    );

    await sessionStore.writeSession(expected);

    final actual = await sessionStore.readSession();
    expect(actual?.serverUrl, expected.serverUrl);
    expect(actual?.accessToken, expected.accessToken);
    expect(actual?.serverName, expected.serverName);
    expect(actual?.serverVersion, expected.serverVersion);
  });

  test('should treat incomplete secure state as no session', () async {
    final store = RecordingKeyValueStore()
      ..writes['connection.server_url'] = 'https://example.test'
      ..writes['connection.access_token'] = 'token';

    final session = await FlutterSecureSessionStore(store).readSession();

    expect(session, isNull);
  });

  test('should roll back session keys when a write fails', () async {
    final store = RecordingKeyValueStore(failingKey: 'connection.user_id');

    await expectLater(
      FlutterSecureSessionStore(store).writeSession(_session()),
      throwsA(isA<StateError>()),
    );

    expect(
      store.deletes,
      containsAll(<String>[
        'connection.server_url',
        'connection.access_token',
        'connection.user_id',
        'connection.username',
        'connection.device_id',
      ]),
    );
  });
}

StoredSession _session() => const StoredSession(
  serverUrl: 'https://example.test',
  accessToken: 'token',
  userId: 'id',
  username: 'alice',
  deviceId: 'device',
);

final class RecordingKeyValueStore implements SecureKeyValueStore {
  RecordingKeyValueStore({this.failingKey});

  final String? failingKey;
  final writes = <String, String>{};
  final deletes = <String>[];

  @override
  Future<void> delete(String key) async => deletes.add(key);

  @override
  Future<String?> read(String key) async => writes[key];

  @override
  Future<void> write(String key, String value) async {
    writes[key] = value;
    if (key == failingKey) {
      throw StateError('write failed');
    }
  }
}
