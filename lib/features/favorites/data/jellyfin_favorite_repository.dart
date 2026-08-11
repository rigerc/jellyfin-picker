import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:jellyfin_picker/core/network/media_browser_authorization.dart';
import 'package:jellyfin_picker/features/favorites/domain/failures/favorite_failure.dart';
import 'package:jellyfin_picker/features/favorites/domain/repositories/favorite_repository.dart';

final class JellyfinFavoriteRepository implements FavoriteRepository {
  const JellyfinFavoriteRepository({
    required this.client,
    required this.serverUrl,
    required this.accessToken,
    required this.deviceId,
    required this.userId,
    this.timeout = const Duration(seconds: 10),
  });

  final http.Client client;
  final String serverUrl;
  final String accessToken;
  final String deviceId;
  final String userId;
  final Duration timeout;

  @override
  Future<FavoriteUpdateResult> setFavorite({
    required String itemId,
    required bool isFavorite,
  }) async {
    final normalizedItemId = itemId.trim();
    if (normalizedItemId.isEmpty) {
      return const FavoriteUpdateFailed(InvalidFavoriteRequestFailure());
    }
    final baseUrl = Uri.tryParse(serverUrl);
    if (baseUrl == null ||
        baseUrl.host.isEmpty ||
        (baseUrl.scheme != 'https' && baseUrl.scheme != 'http') ||
        baseUrl.userInfo.isNotEmpty ||
        baseUrl.query.isNotEmpty ||
        baseUrl.fragment.isNotEmpty ||
        accessToken.isEmpty ||
        deviceId.isEmpty ||
        userId.isEmpty) {
      return const FavoriteUpdateFailed(InvalidFavoriteConfigurationFailure());
    }

    final request =
        http.Request(
            isFavorite ? 'POST' : 'DELETE',
            _favoriteUri(baseUrl, normalizedItemId),
          )
          ..followRedirects = false
          ..headers['Authorization'] = MediaBrowserAuthorization.value(
            deviceId: deviceId,
            token: accessToken,
          );

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await client.send(request).timeout(timeout),
      );
    } on HandshakeException {
      return const FavoriteUpdateFailed(InvalidCertificateFavoriteFailure());
    } on SocketException {
      return const FavoriteUpdateFailed(UnreachableFavoriteFailure());
    } on TimeoutException {
      return const FavoriteUpdateFailed(UnreachableFavoriteFailure());
    } on http.ClientException {
      return const FavoriteUpdateFailed(UnreachableFavoriteFailure());
    }

    return _resultFromResponse(
      response,
      itemId: normalizedItemId,
      requestedValue: isFavorite,
    );
  }

  Uri _favoriteUri(Uri baseUrl, String itemId) => baseUrl.replace(
    pathSegments: <String>[
      ...baseUrl.pathSegments.where((segment) => segment.isNotEmpty),
      'UserFavoriteItems',
      itemId,
    ],
    queryParameters: <String, String>{'userId': userId},
  );

  FavoriteUpdateResult _resultFromResponse(
    http.Response response, {
    required String itemId,
    required bool requestedValue,
  }) {
    if (response.statusCode == 401) {
      return const FavoriteUpdateFailed(ExpiredFavoriteSessionFailure());
    }
    if (response.statusCode == 403) {
      return const FavoriteUpdateFailed(UnauthorizedFavoriteFailure());
    }
    if (response.statusCode == 404) {
      return const FavoriteUpdateFailed(FavoriteItemNotFoundFailure());
    }
    if (response.statusCode >= 500) {
      return const FavoriteUpdateFailed(FavoriteServerFailure());
    }
    if (response.statusCode >= 300 && response.statusCode < 400) {
      return const FavoriteUpdateFailed(UnsafeFavoriteRedirectFailure());
    }
    if (response.statusCode != 200) {
      return const FavoriteUpdateFailed(IncompatibleFavoriteResponseFailure());
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['IsFavorite'] is! bool) {
        return const FavoriteUpdateFailed(
          IncompatibleFavoriteResponseFailure(),
        );
      }
      final updatedValue = decoded['IsFavorite'] as bool;
      if (updatedValue != requestedValue) {
        return const FavoriteUpdateFailed(
          IncompatibleFavoriteResponseFailure(),
        );
      }
      return FavoriteUpdated(itemId: itemId, isFavorite: updatedValue);
    } on FormatException {
      return const FavoriteUpdateFailed(IncompatibleFavoriteResponseFailure());
    }
  }
}
