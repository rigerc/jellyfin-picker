import 'package:jellyfin_picker/features/connection/data/session_store.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/stored_session.dart';

final class FakeSessionStore implements SessionStore {
  FakeSessionStore({this.session});

  StoredSession? session;

  @override
  Future<void> clearSession() async {
    session = null;
  }

  @override
  Future<StoredSession?> readSession() async => session;

  @override
  Future<void> writeSession(StoredSession value) async {
    session = value;
  }
}

final class FakeDeviceIdProvider implements DeviceIdProvider {
  const FakeDeviceIdProvider(this.deviceId);

  final String deviceId;

  @override
  Future<String> loadOrCreate() async => deviceId;
}
