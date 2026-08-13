import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jellyfin_picker/features/connection/data/session_store.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/stored_session.dart';

/// Secure Keychain/Keystore-backed session persistence.
final class FlutterSecureSessionStore implements SessionStore {
  FlutterSecureSessionStore(this.storage);

  static const _serverUrlKey = 'connection.server_url';
  static const _accessTokenKey = 'connection.access_token';
  static const _userIdKey = 'connection.user_id';
  static const _usernameKey = 'connection.username';
  static const _deviceIdKey = 'connection.device_id';
  static const _serverNameKey = 'connection.server_name';
  static const _serverVersionKey = 'connection.server_version';

  final SecureKeyValueStore storage;

  @override
  Future<StoredSession?> readSession() async {
    final values = await Future.wait(<Future<String?>>[
      _readResilient(storage, _serverUrlKey),
      _readResilient(storage, _accessTokenKey),
      _readResilient(storage, _userIdKey),
      _readResilient(storage, _usernameKey),
      _readResilient(storage, _deviceIdKey),
      _readResilient(storage, _serverNameKey),
      _readResilient(storage, _serverVersionKey),
    ]);
    final serverUrl = values[0];
    final accessToken = values[1];
    final userId = values[2];
    final username = values[3];
    final deviceId = values[4];
    if ([
      serverUrl,
      accessToken,
      userId,
      username,
      deviceId,
    ].any((value) => value == null || value.isEmpty)) {
      return null;
    }
    return StoredSession(
      serverUrl: serverUrl ?? '',
      accessToken: accessToken ?? '',
      userId: userId ?? '',
      username: username ?? '',
      deviceId: deviceId ?? '',
      serverName: values[5],
      serverVersion: values[6],
    );
  }

  @override
  Future<void> writeSession(StoredSession session) async {
    final values = <String, String>{
      _serverUrlKey: session.serverUrl,
      _accessTokenKey: session.accessToken,
      _userIdKey: session.userId,
      _usernameKey: session.username,
      _deviceIdKey: session.deviceId,
      if (session.serverName != null) _serverNameKey: session.serverName!,
      if (session.serverVersion != null)
        _serverVersionKey: session.serverVersion!,
    };
    try {
      for (final entry in values.entries) {
        await storage.write(entry.key, entry.value);
      }
    } on Object {
      await Future.wait(
        values.keys.map((key) async {
          try {
            await storage.delete(key);
          } on Object catch (_) {}
        }),
      );
      rethrow;
    }
  }

  @override
  Future<void> clearSession() async {
    await Future.wait(<Future<void>>[
      storage.delete(_serverUrlKey),
      storage.delete(_accessTokenKey),
      storage.delete(_userIdKey),
      storage.delete(_usernameKey),
      storage.delete(_serverNameKey),
      storage.delete(_serverVersionKey),
    ]);
  }
}

/// Securely persists a stable device identifier without storing credentials.
final class SecureDeviceIdProvider implements DeviceIdProvider {
  SecureDeviceIdProvider(this.storage);

  static const _deviceIdKey = 'connection.device_id';

  final SecureKeyValueStore storage;

  @override
  Future<String> loadOrCreate() async {
    final existing = await _readResilient(storage, _deviceIdKey);
    if (existing != null) {
      return existing;
    }
    final generated = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    await storage.write(_deviceIdKey, generated);
    return generated;
  }
}

/// Reads a secure value while absorbing transient keychain/keystore misses.
Future<String?> _readResilient(
  SecureKeyValueStore storage,
  String key, {
  int attempts = 3,
  Duration delay = const Duration(milliseconds: 50),
}) async {
  Object? lastError;
  var sawCleanResult = false;
  for (var attempt = 0; attempt < attempts; attempt++) {
    try {
      final value = await storage.read(key);
      sawCleanResult = true;
      if (value != null && value.isNotEmpty) {
        return value;
      }
    } on Object catch (error) {
      lastError = error;
    }
    if (attempt + 1 < attempts) {
      await Future<void>.delayed(delay);
    }
  }
  if (!sawCleanResult && lastError != null) {
    Error.throwWithStackTrace(lastError, StackTrace.current);
  }
  return null;
}

final class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  const FlutterSecureKeyValueStore(this.storage);

  final FlutterSecureStorage storage;

  @override
  Future<void> delete(String key) => storage.delete(key: key);

  @override
  Future<String?> read(String key) => storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      storage.write(key: key, value: value);
}
