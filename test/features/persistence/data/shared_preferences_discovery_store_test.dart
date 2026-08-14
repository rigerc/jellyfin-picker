import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_snapshot.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_mode.dart';
import 'package:jellyfin_picker/features/persistence/data/shared_preferences_discovery_store.dart';

void main() {
  test('should persist one scoped versioned JSON blob', () async {
    final preferences = RecordingBlobPreferences();
    final store = SharedPreferencesDiscoveryStore(preferences);
    const snapshot = DiscoverySnapshot(
      filter: CatalogFilter(favorite: true),
      mode: DiscoveryMode.swipe,
      likedIds: <String>{'movie-1'},
    );

    await store.write('https://example.test/user-1', snapshot);

    expect(preferences.values, hasLength(1));
    expect(
      preferences.values.keys.single,
      contains('jellyfin_picker.discovery'),
    );
    final encoded = jsonDecode(preferences.values.values.single) as Map;
    expect(encoded['version'], 1);
    expect(encoded['filter'], isA<Map>());
  });

  test('should round trip a scoped snapshot', () async {
    final preferences = RecordingBlobPreferences();
    final store = SharedPreferencesDiscoveryStore(preferences);
    const snapshot = DiscoverySnapshot(
      filter: CatalogFilter(
        searchTerm: 'candy',
        addedWithin: CatalogAddedWindow.ninetyDays,
        sort: CatalogSort.recentlyAdded,
        officialRatings: <String>{'PG-13'},
        watched: false,
      ),
      presets: <String, CatalogFilter>{
        'Recent': CatalogFilter(
          addedWithin: CatalogAddedWindow.thirtyDays,
          favorite: true,
        ),
      },
      mode: DiscoveryMode.shuffle,
      rejectedIds: <String>{'movie-2'},
    );

    await store.write('server/user', snapshot);

    expect(await store.read('server/user'), snapshot);
  });

  test('should isolate snapshots by server and user scope', () async {
    final preferences = RecordingBlobPreferences();
    final store = SharedPreferencesDiscoveryStore(preferences);
    await store.write(
      'https://example.test/user-1',
      const DiscoverySnapshot(likedIds: <String>{'movie-1'}),
    );

    expect(await store.read('https://example.test/user-2'), isNull);
  });

  test('should recover safely from corrupt and mismatched blobs', () async {
    final preferences = RecordingBlobPreferences();
    final store = SharedPreferencesDiscoveryStore(preferences);
    await preferences.write('jellyfin_picker.discovery.invalid', '{bad');

    expect(await store.read('invalid'), isNull);
    await preferences.write(
      preferences.keyFor('invalid'),
      jsonEncode(<String, Object?>{'version': 999}),
    );
    expect(await store.read('invalid'), isNull);
    expect(preferences.removed, contains(preferences.keyFor('invalid')));
  });

  test('should reject oversized blobs before JSON decoding', () async {
    final preferences = RecordingBlobPreferences();
    final store = SharedPreferencesDiscoveryStore(preferences, maxBytes: 8);
    await preferences.write(preferences.keyFor('large'), '{"large":"value"}');

    expect(await store.read('large'), isNull);
    expect(preferences.removed, contains(preferences.keyFor('large')));
  });

  test('should remove only the scoped discovery key', () async {
    final preferences = RecordingBlobPreferences();
    final store = SharedPreferencesDiscoveryStore(preferences);
    await store.write('server/user', const DiscoverySnapshot());
    await preferences.write('secure.session.token', 'keep');

    await store.clear('server/user');

    expect(preferences.values, <String, String>{
      'secure.session.token': 'keep',
    });
    expect(preferences.removed, <String>[preferences.keyFor('server/user')]);
  });

  test('should retain decisions for the validated 2,000-title pool', () async {
    final preferences = RecordingBlobPreferences();
    final store = SharedPreferencesDiscoveryStore(preferences);
    final snapshot = DiscoverySnapshot(
      likedIds: Set<String>.from(
        List<String>.generate(
          1000,
          (index) => 'a${index.toString().padLeft(31, '0')}',
        ),
      ),
      rejectedIds: Set<String>.from(
        List<String>.generate(
          1000,
          (index) => 'b${index.toString().padLeft(31, '0')}',
        ),
      ),
    );

    await store.write('server/user', snapshot);
    final restored = await store.read('server/user');

    expect(restored, snapshot);
  });
}

final class RecordingBlobPreferences implements DiscoveryBlobPreferences {
  final values = <String, String>{};
  final removed = <String>[];

  @override
  String keyFor(String scope) =>
      'jellyfin_picker.discovery.${base64Url.encode(utf8.encode(scope))}';

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
    removed.add(key);
  }
}
