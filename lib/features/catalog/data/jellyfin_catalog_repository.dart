import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:jellyfin_picker/core/network/media_browser_authorization.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_facets.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_library.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_page.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_result.dart';
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
  Future<CatalogPage> loadPage({
    CatalogFilter filter = const CatalogFilter(),
    int startIndex = 0,
    Set<String> excludedIds = const <String>{},
    Set<String> includedIds = const <String>{},
  }) async {
    final baseUrl = Uri.tryParse(serverUrl);
    if (baseUrl == null || baseUrl.host.isEmpty || startIndex < 0) {
      return const CatalogPage(
        candidates: <CatalogCandidate>[],
        hasMore: false,
        nextIndex: 0,
        total: 0,
        failure: IncompatibleCatalogFailure(),
      );
    }
    final capturedUtcNow = (filter.dateWindowAnchor ?? _clock()).toUtc();
    var requestedStartIndex = startIndex;
    while (true) {
      final uri =
          filter.sort == CatalogSort.defaultOrder &&
              !filter.isActive &&
              includedIds.isEmpty
          ? _suggestionsUri(baseUrl, requestedStartIndex)
          : _itemsUri(
              baseUrl,
              requestedStartIndex,
              filter,
              excludedIds: excludedIds,
              includedIds: includedIds,
            );
      final request = await _get(uri);
      final response = request.response;
      if (response == null) {
        return CatalogPage(
          candidates: const <CatalogCandidate>[],
          hasMore: false,
          nextIndex: requestedStartIndex,
          total: 0,
          failure: request.failure,
        );
      }
      final decoded = _decodePage(response, requestedStartIndex);
      if (decoded.failure != null) {
        return CatalogPage(
          candidates: const <CatalogCandidate>[],
          hasMore: false,
          nextIndex: requestedStartIndex,
          total: decoded.total,
          failure: decoded.failure,
        );
      }
      final page = _catalogPage(
        decoded,
        filter,
        capturedUtcNow: capturedUtcNow,
      );
      final shouldContinueConjunctiveGenres =
          filter.genres.length > 1 &&
          page.candidates.isEmpty &&
          page.failure == null &&
          page.hasMore;
      if (!shouldContinueConjunctiveGenres) {
        return page;
      }
      requestedStartIndex = page.nextIndex;
    }
  }

  @override
  Future<CatalogResult<List<CatalogLibrary>>> loadLibraries() async {
    final baseUrl = Uri.tryParse(serverUrl);
    if (baseUrl == null || baseUrl.host.isEmpty) {
      return const CatalogResult<List<CatalogLibrary>>.failure(
        IncompatibleCatalogFailure(),
      );
    }
    final uri = _endpoint(baseUrl, <String>[
      'UserViews',
    ]).replace(queryParameters: <String, String>{'userId': userId});
    final request = await _get(uri);
    final response = request.response;
    if (response == null) {
      return CatalogResult<List<CatalogLibrary>>.failure(request.failure);
    }
    final failure = _responseFailure(response);
    if (failure != null) {
      return CatalogResult<List<CatalogLibrary>>.failure(failure);
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['Items'] is! List) {
        return const CatalogResult<List<CatalogLibrary>>.failure(
          IncompatibleCatalogFailure(),
        );
      }
      final libraries = (decoded['Items'] as List)
          .whereType<Map>()
          .map(_parseLibrary)
          .whereType<CatalogLibrary>()
          .where((library) => library.collectionType.toLowerCase() == 'movies')
          .toList(growable: false);
      return CatalogResult<List<CatalogLibrary>>.success(
        List<CatalogLibrary>.unmodifiable(libraries),
      );
    } on FormatException {
      return const CatalogResult<List<CatalogLibrary>>.failure(
        IncompatibleCatalogFailure(),
      );
    }
  }

  @override
  Future<CatalogResult<CatalogFacets>> loadFacets({String? parentId}) async {
    final baseUrl = Uri.tryParse(serverUrl);
    if (baseUrl == null || baseUrl.host.isEmpty) {
      return const CatalogResult<CatalogFacets>.failure(
        IncompatibleCatalogFailure(),
      );
    }
    final parameters = <String, String>{
      'userId': userId,
      'includeItemTypes': 'Movie',
      if (parentId != null && parentId.isNotEmpty) 'parentId': parentId,
    };
    final legacyRequest = _get(
      _endpoint(baseUrl, <String>[
        'Items',
        'Filters',
      ]).replace(queryParameters: parameters),
    );
    final currentRequest = _get(
      _endpoint(baseUrl, <String>['Items', 'Filters2']).replace(
        queryParameters: <String, String>{...parameters, 'recursive': 'true'},
      ),
    );
    final legacy = await legacyRequest;
    final current = await currentRequest;
    final failedRequest = <_CatalogHttpResult>[
      legacy,
      current,
    ].where((result) => result.failure != null).firstOrNull;
    if (failedRequest != null) {
      return CatalogResult<CatalogFacets>.failure(failedRequest.failure);
    }
    final legacyResponse = legacy.response;
    final currentResponse = current.response;
    if (legacyResponse == null || currentResponse == null) {
      return const CatalogResult<CatalogFacets>.failure(
        IncompatibleCatalogFailure(),
      );
    }
    final responseFailure =
        _responseFailure(legacyResponse) ?? _responseFailure(currentResponse);
    if (responseFailure != null) {
      return CatalogResult<CatalogFacets>.failure(responseFailure);
    }
    try {
      final legacyJson = jsonDecode(legacyResponse.body);
      final currentJson = jsonDecode(currentResponse.body);
      if (legacyJson is! Map || currentJson is! Map) {
        return const CatalogResult<CatalogFacets>.failure(
          IncompatibleCatalogFailure(),
        );
      }
      return CatalogResult<CatalogFacets>.success(
        _parseFacets(legacyJson, currentJson),
      );
    } on FormatException {
      return const CatalogResult<CatalogFacets>.failure(
        IncompatibleCatalogFailure(),
      );
    }
  }

  @override
  Future<CatalogResult<CatalogCandidate>> loadDetails(String itemId) async {
    final baseUrl = Uri.tryParse(serverUrl);
    final normalizedId = itemId.trim();
    if (baseUrl == null || baseUrl.host.isEmpty || normalizedId.isEmpty) {
      return const CatalogResult<CatalogCandidate>.failure(
        IncompatibleCatalogFailure(),
      );
    }
    final uri = _endpoint(baseUrl, <String>[
      'Items',
      normalizedId,
    ]).replace(queryParameters: <String, String>{'userId': userId});
    final request = await _get(uri);
    final response = request.response;
    if (response == null) {
      return CatalogResult<CatalogCandidate>.failure(request.failure);
    }
    final failure = _responseFailure(response);
    if (failure != null) {
      return CatalogResult<CatalogCandidate>.failure(failure);
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return const CatalogResult<CatalogCandidate>.failure(
          IncompatibleCatalogFailure(),
        );
      }
      final candidate = _parseCandidate(
        decoded.map<String, Object?>((key, value) => MapEntry('$key', value)),
      );
      return candidate == null
          ? const CatalogResult<CatalogCandidate>.failure(
              IncompatibleCatalogFailure(),
            )
          : CatalogResult<CatalogCandidate>.success(candidate);
    } on FormatException {
      return const CatalogResult<CatalogCandidate>.failure(
        IncompatibleCatalogFailure(),
      );
    }
  }

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
      final mediaItems = decoded.rawItems.where(
        (item) => item['Type'] == 'Movie',
      );
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

  Future<_CatalogHttpResult> _get(Uri uri) async {
    try {
      return _CatalogHttpResult.response(await _send(uri));
    } on HandshakeException {
      return const _CatalogHttpResult.failure(
        InvalidCertificateCatalogFailure(),
      );
    } on SocketException {
      return const _CatalogHttpResult.failure(UnreachableCatalogFailure());
    } on TimeoutException {
      return const _CatalogHttpResult.failure(UnreachableCatalogFailure());
    } on http.ClientException {
      return const _CatalogHttpResult.failure(UnreachableCatalogFailure());
    }
  }

  CatalogPage _catalogPage(
    _DecodedPage decoded,
    CatalogFilter filter, {
    required DateTime capturedUtcNow,
  }) {
    final mediaItems = decoded.rawItems.where(
      (item) => item['Type'] == 'Movie',
    );
    final parsedItems = mediaItems.map(_parseCandidate).toList(growable: false);
    final candidates = parsedItems
        .whereType<CatalogCandidate>()
        .where((candidate) => filter.matches(candidate, now: capturedUtcNow))
        .toList(growable: false);
    final nextIndex = decoded.startIndex + decoded.rawItemCount;
    final hasMore = decoded.rawItemCount > 0 && nextIndex < decoded.total;
    final malformed =
        decoded.hasMalformedItems ||
        parsedItems.any((candidate) => candidate == null) ||
        mediaItems.any(_hasMalformedMetadata);
    final missingImages = candidates.any(
      (candidate) =>
          candidate.poster.isFallback || candidate.backdrop.isFallback,
    );
    final failure = switch ((
      decoded.total,
      candidates.isEmpty,
      malformed,
      missingImages,
    )) {
      (0, _, _, _) when filter.isActive => const NoCatalogMatchFailure(),
      (0, _, _, _) => const NoAccessibleLibraryFailure(),
      (_, true, _, _) when !hasMore && filter.isActive =>
        const NoCatalogMatchFailure(),
      (_, _, true, _) => const PartialCatalogFailure(),
      (_, _, _, true) => const MissingMetadataCatalogFailure(),
      _ => null,
    };
    return CatalogPage(
      candidates: candidates,
      hasMore: hasMore,
      nextIndex: nextIndex,
      total: decoded.total,
      failure: failure,
    );
  }

  CatalogFailure? _responseFailure(http.Response response) {
    if (response.statusCode == 401) {
      return const ExpiredCatalogFailure();
    }
    if (response.statusCode == 403) {
      return const UnauthorizedCatalogFailure();
    }
    if (response.statusCode >= 500) {
      return const ServerCatalogFailure();
    }
    if (response.statusCode >= 300 && response.statusCode < 400) {
      return const RedirectCatalogFailure();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const IncompatibleCatalogFailure();
    }
    return null;
  }

  Uri _endpoint(Uri baseUrl, List<String> segments) => baseUrl.replace(
    pathSegments: <String>[
      ...baseUrl.pathSegments.where((segment) => segment.isNotEmpty),
      ...segments,
    ],
    query: null,
    fragment: null,
  );

  Uri _itemsUri(
    Uri baseUrl,
    int startIndex,
    CatalogFilter filter, {
    Set<String> excludedIds = const <String>{},
    Set<String> includedIds = const <String>{},
  }) {
    final path = '${baseUrl.path.replaceFirst(RegExp(r'/+$'), '')}/Items';
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
        'parentId': ?filter.libraryId,
        'includeItemTypes': 'Movie',
        'recursive': 'true',
        'fields': 'Genres,PrimaryImageAspectRatio,DateCreated',
        'enableUserData': 'true',
        'enableImages': 'true',
        'enableImageTypes': 'Primary,Backdrop',
        'imageTypeLimit': '1',
        'enableTotalRecordCount': 'true',
        'filters': 'IsNotFolder',
        if (filter.searchTerm.trim().isNotEmpty)
          'searchTerm': filter.searchTerm.trim(),
        if (filter.watched != null) 'isPlayed': '${filter.watched}',
        if (filter.favorite != null) 'isFavorite': '${filter.favorite}',
        if (minimumCommunity != null) 'minCommunityRating': '$minimumCommunity',
        if (minimumCritic != null) 'minCriticRating': '$minimumCritic',
        if (genres.isNotEmpty) 'genres': genres.first,
        if (years.isNotEmpty) 'years': years.join(','),
        if (filter.officialRatings.isNotEmpty)
          'officialRatings': (filter.officialRatings.toList()..sort()).join(
            '|',
          ),
        if (excludedIds.isNotEmpty)
          'excludeItemIds': (excludedIds.toList()..sort()).take(100).join(','),
        if (includedIds.isNotEmpty)
          'ids': (includedIds.toList()..sort()).take(pageSize).join(','),
        ..._sortParameters(
          filter.sort == CatalogSort.defaultOrder
              ? CatalogSort.communityRating
              : filter.sort,
        ),
        'startIndex': '$startIndex',
        'limit': '$pageSize',
      },
    );
  }

  Uri _suggestionsUri(Uri baseUrl, int startIndex) {
    return _endpoint(baseUrl, <String>['Items', 'Suggestions']).replace(
      queryParameters: <String, String>{
        'userId': userId,
        'type': 'Movie',
        'startIndex': '$startIndex',
        'limit': '$pageSize',
        'fields': 'Genres,PrimaryImageAspectRatio,DateCreated',
        'enableUserData': 'true',
        'enableImages': 'true',
        'imageTypeLimit': '1',
        'enableTotalRecordCount': 'true',
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
    final mediaType = item['Type'] == 'Movie' ? CatalogMediaType.movie : null;
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
    final blurHashes = item['ImageBlurHashes'] is Map
        ? (item['ImageBlurHashes'] as Map).map<String, Object?>(
            (key, value) => MapEntry('$key', value),
          )
        : const <String, Object?>{};
    final primaryTag = _string(imageTags['Primary']);
    final backdropTag = backdropTags.firstOrNull;
    final primaryAspectRatio = _number(item['PrimaryImageAspectRatio']);
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
      trailers: _trailers(item['RemoteTrailers']),
      watched: _bool(userData['Played']),
      favorite: _bool(userData['IsFavorite']),
      poster: _image(
        baseUrl: Uri.parse(serverUrl),
        id: id,
        tag: primaryTag,
        backdrop: false,
        aspectRatio: primaryAspectRatio != null && primaryAspectRatio > 0
            ? primaryAspectRatio
            : 0.67,
        blurHash: _blurHash(blurHashes, 'Primary', primaryTag),
      ),
      backdrop: _image(
        baseUrl: Uri.parse(serverUrl),
        id: id,
        tag: backdropTag,
        backdrop: true,
        aspectRatio: 1.78,
        blurHash: _blurHash(blurHashes, 'Backdrop', backdropTag),
      ),
    );
  }

  List<CatalogTrailer> _trailers(Object? value) {
    if (value is! List) {
      return const <CatalogTrailer>[];
    }
    final seen = <Uri>{};
    return value
        .whereType<Map>()
        .map(_parseTrailer)
        .whereType<CatalogTrailer>()
        .where((trailer) => seen.add(trailer.uri))
        .toList(growable: false);
  }

  CatalogTrailer? _parseTrailer(Map<Object?, Object?> trailer) {
    final rawUrl = _string(trailer['Url']);
    if (rawUrl == null) {
      return null;
    }
    final uri = Uri.tryParse(rawUrl);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return null;
    }
    return CatalogTrailer(name: _string(trailer['Name']), uri: uri);
  }

  CatalogImage _image({
    required Uri baseUrl,
    required String id,
    required String? tag,
    required bool backdrop,
    required double aspectRatio,
    required String? blurHash,
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
      aspectRatio: aspectRatio,
      blurHash: blurHash,
    );
  }

  String? _blurHash(
    Map<String, Object?> imageBlurHashes,
    String imageType,
    String? tag,
  ) {
    if (tag == null || imageBlurHashes[imageType] is! Map) {
      return null;
    }
    final hashes = imageBlurHashes[imageType] as Map;
    return _string(hashes[tag]);
  }

  CatalogLibrary? _parseLibrary(Map<Object?, Object?> item) {
    final id = item['Id'];
    final name = item['Name'];
    final collectionType = item['CollectionType'];
    if (id is! String ||
        id.isEmpty ||
        name is! String ||
        name.isEmpty ||
        collectionType is! String ||
        collectionType.isEmpty) {
      return null;
    }
    return CatalogLibrary(id: id, name: name, collectionType: collectionType);
  }

  CatalogFacets _parseFacets(Map legacy, Map current) {
    final genres = <String>{
      ..._stringList(legacy['Genres']),
      ..._nameList(current['Genres']),
    }.toList()..sort();
    final years = _intList(legacy['Years']).toSet().toList()..sort();
    final officialRatings = _stringList(
      legacy['OfficialRatings'],
    ).toSet().toList()..sort();
    final tags = <String>{
      ..._stringList(legacy['Tags']),
      ..._stringList(current['Tags']),
    }.toList()..sort();
    return CatalogFacets(
      genres: List<String>.unmodifiable(genres),
      years: List<int>.unmodifiable(years),
      officialRatings: List<String>.unmodifiable(officialRatings),
      tags: List<String>.unmodifiable(tags),
      audioLanguages: _facetValues(current['AudioLanguages']),
      subtitleLanguages: _facetValues(current['SubtitleLanguages']),
    );
  }

  List<String> _stringList(Object? value) => value is List
      ? value.whereType<String>().where((item) => item.isNotEmpty).toList()
      : const <String>[];

  List<int> _intList(Object? value) =>
      value is List ? value.whereType<int>().toList() : const <int>[];

  List<String> _nameList(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => item['Name'])
            .whereType<String>()
            .where((item) => item.isNotEmpty)
            .toList()
      : const <String>[];

  List<CatalogFacetValue> _facetValues(Object? value) {
    if (value is! List) {
      return const <CatalogFacetValue>[];
    }
    final values =
        value
            .whereType<Map>()
            .map((item) {
              final name = item['Name'];
              final facetValue = item['Value'];
              return name is String &&
                      name.isNotEmpty &&
                      facetValue is String &&
                      facetValue.isNotEmpty
                  ? CatalogFacetValue(name: name, value: facetValue)
                  : null;
            })
            .whereType<CatalogFacetValue>()
            .toList()
          ..sort((left, right) => left.name.compareTo(right.name));
    return List<CatalogFacetValue>.unmodifiable(values);
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

  Map<String, String> _sortParameters(CatalogSort sort) => switch (sort) {
    CatalogSort.defaultOrder => const <String, String>{},
    CatalogSort.random => const <String, String>{'sortBy': 'Random'},
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

final class _CatalogHttpResult {
  const _CatalogHttpResult.response(this.response) : failure = null;

  const _CatalogHttpResult.failure(this.failure) : response = null;

  final http.Response? response;
  final CatalogFailure? failure;
}
