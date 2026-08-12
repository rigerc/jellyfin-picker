import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:jellyfin_picker/core/network/media_browser_authorization.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_page.dart';
import 'package:jellyfin_picker/features/catalog/domain/failures/catalog_failure.dart';
import 'package:jellyfin_picker/features/catalog/domain/repositories/catalog_repository.dart';

/// Paginated Jellyfin catalog transport and deterministic local refinement.
final class JellyfinCatalogRepository implements CatalogRepository {
  JellyfinCatalogRepository({
    required this.client,
    required this.serverUrl,
    required this.accessToken,
    required this.deviceId,
    required this.userId,
    this.pageSize = 50,
    this.timeout = const Duration(seconds: 10),
    DateTime Function()? now,
  }) : _clock = now ?? _utcNow {
    if (pageSize < 1 || pageSize > 50) {
      throw ArgumentError.value(
        pageSize,
        'pageSize',
        'must be between 1 and 50',
      );
    }
  }

  final http.Client client;
  final String serverUrl;
  final String accessToken;
  final String deviceId;
  final String userId;
  final int pageSize;
  final Duration timeout;
  final DateTime Function() _clock;

  @override
  Stream<CatalogPage> streamPages({
    CatalogFilter filter = const CatalogFilter(),
  }) async* {
    final baseUrl = Uri.tryParse(serverUrl);
    if (baseUrl == null || baseUrl.host.isEmpty) {
      yield const CatalogPage(
        candidates: <CatalogCandidate>[],
        hasMore: false,
        nextIndex: 0,
        total: 0,
        failure: IncompatibleCatalogFailure(),
      );
      return;
    }
    final capturedUtcNow = (filter.dateWindowAnchor ?? _clock()).toUtc();
    var startIndex = 0;
    var previousStartIndex = -1;
    String? previousPageFingerprint;
    final seenIds = <String>{};
    var matchedAny = false;
    var total = 0;
    while (startIndex != previousStartIndex) {
      previousStartIndex = startIndex;
      final http.Response response;
      try {
        response = await _send(_itemsUri(baseUrl, startIndex, filter));
      } on HandshakeException {
        yield const CatalogPage(
          candidates: <CatalogCandidate>[],
          hasMore: false,
          nextIndex: 0,
          total: 0,
          failure: InvalidCertificateCatalogFailure(),
        );
        return;
      } on SocketException {
        yield const CatalogPage(
          candidates: <CatalogCandidate>[],
          hasMore: false,
          nextIndex: 0,
          total: 0,
          failure: UnreachableCatalogFailure(),
        );
        return;
      } on TimeoutException {
        yield const CatalogPage(
          candidates: <CatalogCandidate>[],
          hasMore: false,
          nextIndex: 0,
          total: 0,
          failure: UnreachableCatalogFailure(),
        );
        return;
      } on http.ClientException {
        yield const CatalogPage(
          candidates: <CatalogCandidate>[],
          hasMore: false,
          nextIndex: 0,
          total: 0,
          failure: UnreachableCatalogFailure(),
        );
        return;
      }
      final decoded = _decodePage(response, startIndex);
      if (decoded.failure != null) {
        yield CatalogPage(
          candidates: const <CatalogCandidate>[],
          hasMore: false,
          nextIndex: startIndex,
          total: decoded.total,
          failure: decoded.failure,
        );
        return;
      }
      total = decoded.total;
      final fingerprint = decoded.rawItems
          .map((item) => '${item['Id']}:${item['Type']}')
          .join('|');
      if (fingerprint == previousPageFingerprint && fingerprint.isNotEmpty) {
        yield CatalogPage(
          candidates: const <CatalogCandidate>[],
          hasMore: false,
          nextIndex: startIndex,
          total: total,
          failure: const PartialCatalogFailure(),
        );
        return;
      }
      previousPageFingerprint = fingerprint;
      final mediaItems = decoded.rawItems.where((item) {
        return item['Type'] == 'Movie' || item['Type'] == 'Series';
      });
      final parsedItems = mediaItems
          .map(_parseCandidate)
          .toList(growable: false);
      final hasMalformedItem =
          parsedItems.any((candidate) => candidate == null) ||
          decoded.hasMalformedItems ||
          mediaItems.any(_hasMalformedMetadata);
      final candidates = parsedItems
          .whereType<CatalogCandidate>()
          .where((candidate) => seenIds.add(candidate.id))
          .where((candidate) => filter.matches(candidate, now: capturedUtcNow))
          .toList(growable: false);
      final hasMissingMetadata = candidates.any(
        (candidate) =>
            candidate.poster.isFallback || candidate.backdrop.isFallback,
      );
      matchedAny = matchedAny || candidates.isNotEmpty;
      final returnedCount = decoded.rawItemCount;
      final nextIndex = decoded.startIndex + returnedCount;
      final hasMore = returnedCount > 0 && nextIndex < total;
      final isEmptyWithRemaining =
          returnedCount == 0 && decoded.startIndex < total;
      final isFinal = !hasMore;
      CatalogFailure? terminalFailure;
      if (isFinal && total == 0 && filter.isActive) {
        terminalFailure = const NoCatalogMatchFailure();
      } else if (isFinal && total == 0) {
        terminalFailure = const NoAccessibleLibraryFailure();
      } else if (isEmptyWithRemaining) {
        terminalFailure = const PartialCatalogFailure();
      } else if (isFinal && filter.isActive && !matchedAny) {
        terminalFailure = const NoCatalogMatchFailure();
      } else if (hasMalformedItem) {
        terminalFailure = const PartialCatalogFailure();
      } else if (hasMissingMetadata) {
        terminalFailure = const MissingMetadataCatalogFailure();
      }
      yield CatalogPage(
        candidates: candidates,
        hasMore: hasMore,
        nextIndex: nextIndex,
        total: total,
        failure: terminalFailure,
      );
      if (!hasMore) {
        return;
      }
      startIndex = nextIndex;
    }
  }

  Future<http.Response> _send(Uri uri) async {
    final request = http.Request('GET', uri)
      ..followRedirects = false
      ..headers.addAll(<String, String>{
        'Authorization': MediaBrowserAuthorization.value(
          deviceId: deviceId,
          token: accessToken,
        ),
      });
    return http.Response.fromStream(
      await client.send(request).timeout(timeout),
    );
  }

  Uri _itemsUri(Uri baseUrl, int startIndex, CatalogFilter filter) {
    final path = '${baseUrl.path.replaceFirst(RegExp(r'/+$'), '')}/Items';
    final selectedMediaTypes = <String>[];
    if (filter.mediaTypes.contains(CatalogMediaType.movie)) {
      selectedMediaTypes.add('Movie');
    }
    if (filter.mediaTypes.contains(CatalogMediaType.series)) {
      selectedMediaTypes.add('Series');
    }
    final mediaTypes = selectedMediaTypes.isEmpty
        ? 'Movie,Series'
        : selectedMediaTypes.join(',');
    final genres = filter.genres.toList()..sort();
    final years =
        filter.decades
            .expand(
              (decade) =>
                  Iterable<int>.generate(10, (offset) => decade + offset),
            )
            .toSet()
            .toList()
          ..sort();
    final minimumCommunity = filter.minimumCommunityRating;
    final minimumCritic = filter.minimumCriticRating;
    return baseUrl.replace(
      path: path,
      queryParameters: <String, String>{
        'userId': userId,
        'includeItemTypes': mediaTypes,
        'recursive': 'true',
        'fields': 'Overview,Genres,People,PrimaryImageAspectRatio,DateCreated',
        'enableUserData': 'true',
        'enableImages': 'true',
        'enableImageTypes': 'Primary,Backdrop',
        'imageTypeLimit': '2',
        'enableTotalRecordCount': 'true',
        'filters': 'IsNotFolder',
        if (filter.searchTerm.trim().isNotEmpty)
          'searchTerm': filter.searchTerm.trim(),
        if (filter.watched != null) 'isPlayed': '${filter.watched}',
        if (filter.favorite != null) 'isFavorite': '${filter.favorite}',
        if (minimumCommunity != null) 'minCommunityRating': '$minimumCommunity',
        if (minimumCritic != null) 'minCriticRating': '$minimumCritic',
        if (genres.isNotEmpty) 'genres': genres.join('|'),
        if (years.isNotEmpty) 'years': years.join(','),
        if (filter.officialRatings.isNotEmpty)
          'officialRatings': (filter.officialRatings.toList()..sort()).join(
            '|',
          ),
        if (filter.seriesStatuses.isNotEmpty)
          'seriesStatus': _seriesStatuses(filter),
        ..._sortParameters(filter.sort),
        'startIndex': '$startIndex',
        'limit': '$pageSize',
      },
    );
  }

  _DecodedPage _decodePage(http.Response response, int requestedStartIndex) {
    if (response.statusCode == 401) {
      return const _DecodedPage.failure(ExpiredCatalogFailure());
    }
    if (response.statusCode == 403) {
      return const _DecodedPage.failure(UnauthorizedCatalogFailure());
    }
    if (response.statusCode >= 500) {
      return const _DecodedPage.failure(ServerCatalogFailure());
    }
    if (response.statusCode >= 300 && response.statusCode < 400) {
      return const _DecodedPage.failure(RedirectCatalogFailure());
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const _DecodedPage.failure(IncompatibleCatalogFailure());
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['Items'] is! List) {
        return const _DecodedPage.failure(IncompatibleCatalogFailure());
      }
      final rawItems = decoded['Items'] as List;
      final hasMalformedItems = rawItems.any((item) => item is! Map);
      final items = rawItems
          .whereType<Map>()
          .map(
            (item) => item.map<String, Object?>(
              (key, value) => MapEntry('$key', value),
            ),
          )
          .toList(growable: false);
      final total = decoded['TotalRecordCount'];
      if (total is! int || total < 0) {
        return const _DecodedPage.failure(IncompatibleCatalogFailure());
      }
      final startIndex = decoded['StartIndex'];
      return _DecodedPage(
        items,
        total,
        startIndex is int && startIndex >= 0 ? startIndex : requestedStartIndex,
        hasMalformedItems,
        rawItems.length,
      );
    } on Object catch (_) {
      return const _DecodedPage.failure(IncompatibleCatalogFailure());
    }
  }

  CatalogCandidate? _parseCandidate(Map<String, Object?> item) {
    final id = item['Id'];
    final name = item['Name'];
    final type = item['Type'];
    final mediaType = switch (type) {
      'Movie' => CatalogMediaType.movie,
      'Series' => CatalogMediaType.series,
      _ => null,
    };
    if (id is! String ||
        id.isEmpty ||
        name is! String ||
        name.isEmpty ||
        mediaType == null) {
      return null;
    }
    final userData = item['UserData'] is Map
        ? (item['UserData'] as Map).map<String, Object?>(
            (key, value) => MapEntry('$key', value),
          )
        : const <String, Object?>{};
    final genres = item['Genres'] is List
        ? (item['Genres'] as List)
              .whereType<String>()
              .map((genre) => genre.toLowerCase())
              .toSet()
        : const <String>{};
    final imageTags = item['ImageTags'] is Map
        ? (item['ImageTags'] as Map).map<String, Object?>(
            (key, value) => MapEntry('$key', value),
          )
        : const <String, Object?>{};
    final backdropTags = item['BackdropImageTags'] is List
        ? (item['BackdropImageTags'] as List).whereType<String>().toList(
            growable: false,
          )
        : const <String>[];
    return CatalogCandidate(
      id: id,
      name: name,
      mediaType: mediaType,
      year: item['ProductionYear'] is int
          ? item['ProductionYear'] as int
          : null,
      runtimeMinutes: _runtimeMinutes(item['RunTimeTicks']),
      genres: genres,
      communityRating: _number(item['CommunityRating']),
      criticRating: _number(item['CriticRating']),
      officialRating: _string(item['OfficialRating']),
      status: _string(item['Status']),
      dateCreated: _dateTime(item['DateCreated']),
      overview: _string(item['Overview']),
      cast: item['People'] is List
          ? (item['People'] as List)
                .whereType<Map>()
                .map((person) => person['Name'])
                .whereType<String>()
                .toList(growable: false)
          : const <String>[],
      watched: _bool(userData['Played']),
      favorite: _bool(userData['IsFavorite']),
      poster: _image(
        baseUrl: Uri.parse(serverUrl),
        id: id,
        tag: _string(imageTags['Primary']),
        backdrop: false,
      ),
      backdrop: _image(
        baseUrl: Uri.parse(serverUrl),
        id: id,
        tag: backdropTags.isEmpty ? null : backdropTags.first,
        backdrop: true,
      ),
    );
  }

  CatalogImage _image({
    required Uri baseUrl,
    required String id,
    required String? tag,
    required bool backdrop,
  }) {
    if (tag == null || tag.isEmpty) {
      return const CatalogImage.fallback();
    }
    final kind = backdrop ? 'Backdrop' : 'Primary';
    final path =
        '${baseUrl.path.replaceFirst(RegExp(r'/+$'), '')}/Items/$id/Images/$kind';
    return CatalogImage(
      uri: baseUrl.replace(
        path: path,
        queryParameters: <String, String>{'tag': tag},
      ),
      isFallback: false,
      aspectRatio: backdrop ? 1.78 : 0.67,
    );
  }

  int? _runtimeMinutes(Object? ticks) =>
      ticks is int ? ticks ~/ 600000000 : null;

  double? _number(Object? value) => value is num ? value.toDouble() : null;

  DateTime? _dateTime(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;

  String? _string(Object? value) => value is String ? value : null;

  bool? _bool(Object? value) => value is bool ? value : null;

  bool _hasMalformedMetadata(Map<String, Object?> item) {
    final userData = item['UserData'];
    if (userData != null && userData is! Map) {
      return true;
    }
    if (userData is Map) {
      final played = userData['Played'];
      final favorite = userData['IsFavorite'];
      if ((played != null && played is! bool) ||
          (favorite != null && favorite is! bool)) {
        return true;
      }
    }
    final genres = item['Genres'];
    final imageTags = item['ImageTags'];
    final backdropTags = item['BackdropImageTags'];
    final people = item['People'];
    return (genres != null && genres is! List) ||
        (imageTags != null && imageTags is! Map) ||
        (backdropTags != null && backdropTags is! List) ||
        (people != null && people is! List) ||
        (item['RunTimeTicks'] != null && item['RunTimeTicks'] is! int) ||
        (item['ProductionYear'] != null && item['ProductionYear'] is! int) ||
        (item['CommunityRating'] != null && item['CommunityRating'] is! num) ||
        (item['CriticRating'] != null && item['CriticRating'] is! num) ||
        (item['DateCreated'] != null &&
            (item['DateCreated'] is! String ||
                _dateTime(item['DateCreated']) == null));
  }

  String _seriesStatuses(CatalogFilter filter) {
    final statuses = filter.seriesStatuses.toList()
      ..sort((left, right) => left.name.compareTo(right.name));
    return statuses
        .map(
          (status) => switch (status) {
            CatalogSeriesStatus.continuing => 'Continuing',
            CatalogSeriesStatus.ended => 'Ended',
          },
        )
        .join(',');
  }

  Map<String, String> _sortParameters(CatalogSort sort) => switch (sort) {
    CatalogSort.defaultOrder => const <String, String>{},
    CatalogSort.recentlyAdded => const <String, String>{
      'sortBy': 'DateCreated',
      'sortOrder': 'Descending',
    },
    CatalogSort.title => const <String, String>{
      'sortBy': 'SortName',
      'sortOrder': 'Ascending',
    },
    CatalogSort.releaseYear => const <String, String>{
      'sortBy': 'ProductionYear',
      'sortOrder': 'Descending',
    },
    CatalogSort.communityRating => const <String, String>{
      'sortBy': 'CommunityRating',
      'sortOrder': 'Descending',
    },
    CatalogSort.runtime => const <String, String>{
      'sortBy': 'Runtime',
      'sortOrder': 'Ascending',
    },
  };

  static DateTime _utcNow() => DateTime.now().toUtc();
}

final class _DecodedPage {
  const _DecodedPage(
    this.rawItems,
    this.total,
    this.startIndex,
    this.hasMalformedItems,
    this.rawItemCount,
  ) : failure = null;

  const _DecodedPage.failure(this.failure)
    : rawItems = const <Map<String, Object?>>[],
      total = 0,
      startIndex = 0,
      hasMalformedItems = false,
      rawItemCount = 0;

  final List<Map<String, Object?>> rawItems;
  final int total;
  final int startIndex;
  final bool hasMalformedItems;
  final int rawItemCount;
  final CatalogFailure? failure;
}
