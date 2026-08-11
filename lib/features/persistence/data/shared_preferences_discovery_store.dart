import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_snapshot.dart';
import 'package:jellyfin_picker/features/discovery/domain/repositories/discovery_store.dart';

abstract interface class DiscoveryBlobPreferences {
  String keyFor(String scope);

  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> remove(String key);
}

final class SharedPreferencesAsyncBlobPreferences
    implements DiscoveryBlobPreferences {
  SharedPreferencesAsyncBlobPreferences({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  String keyFor(String scope) =>
      'jellyfin_picker.discovery.${base64Url.encode(utf8.encode(scope))}';

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> remove(String key) => _preferences.remove(key);
}

final class SharedPreferencesDiscoveryStore implements DiscoveryStore {
  SharedPreferencesDiscoveryStore(this.preferences, {this.maxBytes = 262144});

  final DiscoveryBlobPreferences preferences;
  final int maxBytes;

  @override
  Future<DiscoverySnapshot?> read(String scope) async {
    final key = preferences.keyFor(scope);
    try {
      final value = await preferences.read(key);
      if (value == null) {
        return null;
      }
      if (utf8.encode(value).length > maxBytes) {
        await _discard(key);
        return null;
      }
      final snapshot = DiscoverySnapshot.fromJson(jsonDecode(value));
      if (snapshot == null) {
        await _discard(key);
      }
      return snapshot;
    } on Object catch (_) {
      await _discard(key);
      return null;
    }
  }

  Future<void> _discard(String key) async {
    try {
      await preferences.remove(key);
    } on Object catch (_) {
      // Corruption recovery is best effort; the read remains safe.
    }
  }

  @override
  Future<void> write(String scope, DiscoverySnapshot snapshot) async {
    final encoded = jsonEncode(snapshot.toJson());
    final bytes = Uint8List.fromList(utf8.encode(encoded));
    if (bytes.length > maxBytes) {
      throw const DiscoveryPersistenceException('discovery data exceeds bound');
    }
    await preferences.write(preferences.keyFor(scope), encoded);
  }

  @override
  Future<void> clear(String scope) =>
      preferences.remove(preferences.keyFor(scope));
}

final class DiscoveryPersistenceException implements Exception {
  const DiscoveryPersistenceException(this.message);

  final String message;
}
