import 'package:jellyfin_picker/core/media/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_mode.dart';
import 'package:jellyfin_picker/features/discovery/domain/serialization/catalog_filter_codec.dart';

final class DiscoverySnapshot {
  static const maxDecisionIdCount = 2000;

  const DiscoverySnapshot({
    this.filter = const CatalogFilter(),
    this.presets = const <String, CatalogFilter>{},
    this.likedIds = const <String>{},
    this.rejectedIds = const <String>{},
    this.recentPickIds = const <String>[],
    this.mode = DiscoveryMode.grid,
    this.position = 0,
    this.currentRevealId,
    this.currentPickId,
  });

  final CatalogFilter filter;
  final Map<String, CatalogFilter> presets;
  final Set<String> likedIds;
  final Set<String> rejectedIds;
  final List<String> recentPickIds;
  final DiscoveryMode mode;
  final int position;
  final String? currentRevealId;
  final String? currentPickId;

  Map<String, Object?> toJson() {
    final persistedRejectedIds = _boundedIds(rejectedIds, maxDecisionIdCount);
    final persistedLikedIds = _boundedIds(
      likedIds.difference(rejectedIds),
      maxDecisionIdCount - persistedRejectedIds.length,
    );
    return <String, Object?>{
      'version': 1,
      'filter': CatalogFilterCodec.encode(filter),
      'presets': <String, Object?>{
        for (final entry in _boundedPresets(presets).entries)
          entry.key: CatalogFilterCodec.encode(entry.value),
      },
      'likedIds': persistedLikedIds,
      'rejectedIds': persistedRejectedIds,
      'recentPickIds': _uniqueNonEmpty(
        recentPickIds.where((id) => !rejectedIds.contains(id)),
      ).take(50).toList(),
      'mode': mode.name,
      'position': position < 0 ? 0 : position,
      'currentRevealId': rejectedIds.contains(currentRevealId)
          ? null
          : currentRevealId,
      'currentPickId': rejectedIds.contains(currentPickId)
          ? null
          : currentPickId,
    };
  }

  static DiscoverySnapshot? fromJson(Object? value) {
    if (value is! Map || value['version'] != 1) {
      return null;
    }
    final filter = CatalogFilterCodec.decode(value['filter']);
    final presets = _decodePresets(value['presets']);
    final likedIds = _decodeIds(value['likedIds']);
    final rejectedIds = _decodeIds(value['rejectedIds']);
    final recentPickIds = _decodeList(value['recentPickIds']);
    final mode = _decodeMode(value['mode']);
    final position = value['position'];
    if (filter == null ||
        presets == null ||
        likedIds == null ||
        rejectedIds == null ||
        recentPickIds == null ||
        mode == null ||
        position is! int ||
        position < 0) {
      return null;
    }
    if (<String>{...likedIds, ...rejectedIds}.length > maxDecisionIdCount) {
      return null;
    }
    final normalizedLikedIds = likedIds.difference(rejectedIds);
    final currentRevealId = _nullableString(value['currentRevealId']);
    final currentPickId = _nullableString(value['currentPickId']);
    return DiscoverySnapshot(
      filter: filter,
      presets: presets,
      likedIds: normalizedLikedIds,
      rejectedIds: rejectedIds,
      recentPickIds: _uniqueNonEmpty(
        recentPickIds.where((id) => !rejectedIds.contains(id)),
      ),
      mode: mode,
      position: position,
      currentRevealId: rejectedIds.contains(currentRevealId)
          ? null
          : currentRevealId,
      currentPickId: rejectedIds.contains(currentPickId) ? null : currentPickId,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DiscoverySnapshot &&
      _filterEquals(other.filter, filter) &&
      _mapEquals(other.presets, presets) &&
      _setEquals(other.likedIds, likedIds) &&
      _setEquals(other.rejectedIds, rejectedIds) &&
      _listEquals(other.recentPickIds, recentPickIds) &&
      other.mode == mode &&
      other.position == position &&
      other.currentRevealId == currentRevealId &&
      other.currentPickId == currentPickId;

  @override
  int get hashCode => Object.hash(
    CatalogFilterCodec.encode(filter).toString(),
    Object.hashAllUnordered(
      presets.entries.map(
        (entry) => Object.hash(
          entry.key,
          CatalogFilterCodec.encode(entry.value).toString(),
        ),
      ),
    ),
    Object.hashAllUnordered(likedIds),
    Object.hashAllUnordered(rejectedIds),
    Object.hashAll(recentPickIds),
    mode,
    position,
    currentRevealId,
    currentPickId,
  );

  static Map<String, CatalogFilter>? _decodePresets(Object? value) {
    if (value is! Map) {
      return null;
    }
    if (value.length > 20) {
      return null;
    }
    final result = <String, CatalogFilter>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        return null;
      }
      final name = (entry.key as String).trim();
      if (name.isEmpty || name.length > 50 || result.containsKey(name)) {
        return null;
      }
      final filter = CatalogFilterCodec.decode(entry.value);
      if (filter == null) {
        return null;
      }
      result[name] = filter;
    }
    return result;
  }

  static Set<String>? _decodeIds(Object? value) {
    if (value is! List ||
        value.length > maxDecisionIdCount ||
        !value.every((item) => item is String)) {
      return null;
    }
    return value.whereType<String>().where((item) => item.isNotEmpty).toSet();
  }

  static List<String>? _decodeList(Object? value) {
    if (value is! List ||
        value.length > 50 ||
        !value.every((item) => item is String)) {
      return null;
    }
    return _uniqueNonEmpty(value.whereType<String>());
  }

  static List<String> _uniqueNonEmpty(Iterable<String> values) {
    final result = <String>[];
    final seen = <String>{};
    for (final value in values) {
      if (value.isNotEmpty && seen.add(value)) {
        result.add(value);
      }
    }
    return List<String>.unmodifiable(result);
  }

  static DiscoveryMode? _decodeMode(Object? value) => switch (value) {
    'grid' => DiscoveryMode.grid,
    'swipe' => DiscoveryMode.swipe,
    'shuffle' => DiscoveryMode.shuffle,
    _ => null,
  };

  static String? _nullableString(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! String || value.isEmpty) {
      return null;
    }
    return value;
  }

  static List<String> _boundedIds(Set<String> ids, int limit) =>
      _boundedList(ids.toList()..sort(), limit);

  static List<String> _boundedList(List<String> values, int limit) =>
      List<String>.unmodifiable(values.take(limit));

  static Map<String, CatalogFilter> _boundedPresets(
    Map<String, CatalogFilter> presets,
  ) {
    final result = <String, CatalogFilter>{};
    for (final entry in presets.entries.take(20)) {
      result[entry.key] = entry.value;
    }
    return Map<String, CatalogFilter>.unmodifiable(result);
  }

  static bool _setEquals<T>(Set<T> left, Set<T> right) =>
      left.length == right.length && left.containsAll(right);

  static bool _listEquals<T>(List<T> left, List<T> right) =>
      left.length == right.length &&
      left.asMap().entries.every((entry) => entry.value == right[entry.key]);

  static bool _mapEquals<K, V>(Map<K, V> left, Map<K, V> right) =>
      left.length == right.length &&
      left.entries.every(
        (entry) =>
            right[entry.key] is CatalogFilter &&
            entry.value is CatalogFilter &&
            _filterEquals(
              right[entry.key] as CatalogFilter,
              entry.value as CatalogFilter,
            ),
      );

  static bool _filterEquals(CatalogFilter left, CatalogFilter right) =>
      CatalogFilterCodec.encode(left).toString() ==
      CatalogFilterCodec.encode(right).toString();
}
