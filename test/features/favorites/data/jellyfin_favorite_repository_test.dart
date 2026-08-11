import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:jellyfin_picker/features/favorites/data/jellyfin_favorite_repository.dart';
import 'package:jellyfin_picker/features/favorites/domain/failures/favorite_failure.dart';
import 'package:jellyfin_picker/features/favorites/domain/repositories/favorite_repository.dart';

import '../../../shared/recording_http_client.dart';

void main() {
  group('JellyfinFavoriteRepository', () {
    test('should mark only the requested item as favorite', () async {
      final client = RecordingHttpClient(
        (request) async => _userData(isFavorite: true),
      );
      final repository = _repository(
        client,
        serverUrl: 'https://host/jellyfin/',
      );

      final result = await repository.setFavorite(
        itemId: 'movie id',
        isFavorite: true,
      );
      final request = client.requests.single;

      expect(result, isA<FavoriteUpdated>());
      expect((result as FavoriteUpdated).isFavorite, isTrue);
      expect(request.method, 'POST');
      expect(request.url.path, '/jellyfin/UserFavoriteItems/movie%20id');
      expect(request.url.queryParameters, <String, String>{
        'userId': 'user-id',
      });
      expect(request.followRedirects, isFalse);
      expect(request.headers['authorization'], contains('Token="token"'));
      expect(request.url.toString(), isNot(contains('UserPlayedItems')));
    });

    test('should unmark only the requested item as favorite', () async {
      final client = RecordingHttpClient(
        (request) async => _userData(isFavorite: false),
      );
      final repository = _repository(client);

      final result = await repository.setFavorite(
        itemId: 'movie-id',
        isFavorite: false,
      );
      final request = client.requests.single;

      expect(result, isA<FavoriteUpdated>());
      expect((result as FavoriteUpdated).isFavorite, isFalse);
      expect(request.method, 'DELETE');
      expect(request.url.path, '/UserFavoriteItems/movie-id');
      expect(request.url.toString(), isNot(contains('UserPlayedItems')));
    });

    test('should reject an empty item id without sending a request', () async {
      final client = RecordingHttpClient(
        (request) async => _userData(isFavorite: true),
      );
      final repository = _repository(client);

      final result = await repository.setFavorite(
        itemId: '   ',
        isFavorite: true,
      );

      expect(
        (result as FavoriteUpdateFailed).failure,
        isA<InvalidFavoriteRequestFailure>(),
      );
      expect(client.requests, isEmpty);
    });

    for (final scenario in <({int status, FavoriteFailure expected})>[
      (status: 401, expected: const ExpiredFavoriteSessionFailure()),
      (status: 403, expected: const UnauthorizedFavoriteFailure()),
      (status: 404, expected: const FavoriteItemNotFoundFailure()),
      (status: 503, expected: const FavoriteServerFailure()),
      (status: 302, expected: const UnsafeFavoriteRedirectFailure()),
      (status: 418, expected: const IncompatibleFavoriteResponseFailure()),
    ]) {
      test('should map HTTP ${scenario.status} to a typed failure', () async {
        final repository = _repository(
          RecordingHttpClient(
            (request) async => http.Response('', scenario.status),
          ),
        );

        final result = await repository.setFavorite(
          itemId: 'movie-id',
          isFavorite: true,
        );

        expect(
          (result as FavoriteUpdateFailed).failure.runtimeType,
          scenario.expected.runtimeType,
        );
      });
    }

    test('should reject malformed success data', () async {
      final repository = _repository(
        RecordingHttpClient(
          (request) async => http.Response(
            jsonEncode(<String, Object?>{'IsFavorite': 'yes'}),
            200,
          ),
        ),
      );

      final result = await repository.setFavorite(
        itemId: 'movie-id',
        isFavorite: true,
      );

      expect(
        (result as FavoriteUpdateFailed).failure,
        isA<IncompatibleFavoriteResponseFailure>(),
      );
    });

    test(
      'should reject a success value that contradicts the request',
      () async {
        final repository = _repository(
          RecordingHttpClient((request) async => _userData(isFavorite: false)),
        );

        final result = await repository.setFavorite(
          itemId: 'movie-id',
          isFavorite: true,
        );

        expect(
          (result as FavoriteUpdateFailed).failure,
          isA<IncompatibleFavoriteResponseFailure>(),
        );
      },
    );

    test('should classify invalid TLS without bypassing it', () async {
      final repository = _repository(
        RecordingHttpClient(
          (request) async => throw const HandshakeException('untrusted'),
        ),
      );

      final result = await repository.setFavorite(
        itemId: 'movie-id',
        isFavorite: true,
      );

      expect(
        (result as FavoriteUpdateFailed).failure,
        isA<InvalidCertificateFavoriteFailure>(),
      );
    });

    test('should classify socket failures as unreachable', () async {
      final repository = _repository(
        RecordingHttpClient(
          (request) async => throw const SocketException('offline'),
        ),
      );

      final result = await repository.setFavorite(
        itemId: 'movie-id',
        isFavorite: true,
      );

      expect(
        (result as FavoriteUpdateFailed).failure,
        isA<UnreachableFavoriteFailure>(),
      );
    });

    test('should classify timeouts as unreachable', () async {
      final repository = _repository(
        RecordingHttpClient((request) => Completer<http.Response>().future),
        timeout: const Duration(milliseconds: 1),
      );

      final result = await repository.setFavorite(
        itemId: 'movie-id',
        isFavorite: true,
      );

      expect(
        (result as FavoriteUpdateFailed).failure,
        isA<UnreachableFavoriteFailure>(),
      );
    });

    test('should reject an invalid server URL without a request', () async {
      final client = RecordingHttpClient(
        (request) async => _userData(isFavorite: true),
      );
      final repository = _repository(client, serverUrl: 'not a url');

      final result = await repository.setFavorite(
        itemId: 'movie-id',
        isFavorite: true,
      );

      expect(
        (result as FavoriteUpdateFailed).failure,
        isA<InvalidFavoriteConfigurationFailure>(),
      );
      expect(client.requests, isEmpty);
    });

    test('should reject server URLs containing credentials', () async {
      final client = RecordingHttpClient(
        (request) async => _userData(isFavorite: true),
      );
      final repository = _repository(
        client,
        serverUrl: 'https://name:password@host',
      );

      final result = await repository.setFavorite(
        itemId: 'movie-id',
        isFavorite: true,
      );

      expect(
        (result as FavoriteUpdateFailed).failure,
        isA<InvalidFavoriteConfigurationFailure>(),
      );
      expect(client.requests, isEmpty);
    });

    test('should reject missing authentication configuration', () async {
      final client = RecordingHttpClient(
        (request) async => _userData(isFavorite: true),
      );
      final repository = _repository(client, accessToken: '');

      final result = await repository.setFavorite(
        itemId: 'movie-id',
        isFavorite: true,
      );

      expect(
        (result as FavoriteUpdateFailed).failure,
        isA<InvalidFavoriteConfigurationFailure>(),
      );
      expect(client.requests, isEmpty);
    });
  });
}

JellyfinFavoriteRepository _repository(
  http.Client client, {
  String serverUrl = 'https://host',
  String accessToken = 'token',
  Duration timeout = const Duration(seconds: 1),
}) => JellyfinFavoriteRepository(
  client: client,
  serverUrl: serverUrl,
  accessToken: accessToken,
  deviceId: 'device-id',
  userId: 'user-id',
  timeout: timeout,
);

http.Response _userData({required bool isFavorite}) => http.Response(
  jsonEncode(<String, Object?>{
    'ItemId': 'movie-id',
    'IsFavorite': isFavorite,
    'Played': true,
  }),
  200,
  headers: <String, String>{'content-type': 'application/json'},
);
