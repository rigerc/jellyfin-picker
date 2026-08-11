import 'package:jellyfin_picker/features/connection/domain/entities/stored_session.dart';

abstract interface class SecureKeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

abstract interface class SessionStore {
  Future<StoredSession?> readSession();

  Future<void> writeSession(StoredSession session);

  Future<void> clearSession();
}

abstract interface class DeviceIdProvider {
  Future<String> loadOrCreate();
}
