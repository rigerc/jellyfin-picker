import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:jellyfin_picker/features/catalog/data/jellyfin_catalog_repository.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/catalog/domain/failures/catalog_failure.dart';
import '../../../shared/recording_http_client.dart';

void main() {
  test('should reject page sizes outside the bounded runtime range', () {
    expect(
      () => JellyfinCatalogRepository(
        client: RecordingHttpClient((request) async => http.Response('', 200)),
        serverUrl: 'https://example.test',
        accessToken: 'token',
        deviceId: 'device',
        userId: 'user-id',
        pageSize: 0,
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => JellyfinCatalogRepository(
        client: RecordingHttpClient((request) async => http.Response('', 200)),
        serverUrl: 'https://example.test',
        accessToken: 'token',
        deviceId: 'device',
        userId: 'user-id',
        pageSize: 51,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
  test(
    'should request bounded movie and series pages with authenticated metadata',
    () async {
      final client = RecordingHttpClient(
        (request) async => _jsonResponse({
          'Items': <Map<String, Object?>>[_movieJson()],
          'TotalRecordCount': 1,
        }),
      );
      final repository = JellyfinCatalogRepository(
        client: client,
        serverUrl: 'https://example.test/jellyfin/',
        accessToken: 'secret-token',
        deviceId: 'device-id',
        userId: 'user-id',
      );

      final page = await repository.streamPages().first;
      final request = client.requests.single;

      expect(page.candidates.single.name, 'Candy Movie');
      expect(request.url.path, '/jellyfin/Items');
      expect(request.url.queryParameters['userId'], 'user-id');
      expect(request.url.queryParameters['includeItemTypes'], 'Movie,Series');
      expect(request.url.queryParameters['recursive'], 'true');
      expect(request.url.queryParameters['limit'], '50');
      expect(request.url.queryParameters['enableUserData'], 'true');
      expect(request.url.queryParameters['enableImages'], 'true');
      expect(
        request.url.queryParameters['enableImageTypes'],
        'Primary,Backdrop',
      );
      expect(request.url.queryParameters['enableTotalRecordCount'], 'true');
      expect(request.url.queryParameters['filters'], 'IsNotFolder');
      expect(
        request.url.queryParameters['fields'],
        'Overview,Genres,People,PrimaryImageAspectRatio,DateCreated',
      );
      expect(request.followRedirects, isFalse);
      expect(
        request.headers['authorization'],
        contains('Token="secret-token"'),
      );
    },
  );

  test('should exclude episodes and expose fallback image metadata', () async {
    final client = RecordingHttpClient(
      (request) async => _jsonResponse({
        'Items': <Map<String, Object?>>[
          _movieWithoutImagesJson(),
          _episodeJson(),
        ],
        'TotalRecordCount': 2,
      }),
    );
    final repository = JellyfinCatalogRepository(
      client: client,
      serverUrl: 'https://example.test',
      accessToken: 'token',
      deviceId: 'device',
      userId: 'user-id',
    );

    final page = await repository.streamPages().first;

    expect(page.candidates, hasLength(1));
    expect(page.candidates.single.poster.isFallback, isTrue);
    expect(page.failure, isA<MissingMetadataCatalogFailure>());
  });

  test('should map whole Series metadata and safe image URIs', () async {
    final repository = JellyfinCatalogRepository(
      client: RecordingHttpClient(
        (request) async => _jsonResponse({
          'Items': <Map<String, Object?>>[_seriesJson()],
          'TotalRecordCount': 1,
        }),
      ),
      serverUrl: 'https://example.test/jellyfin',
      accessToken: 'token',
      deviceId: 'device',
      userId: 'user-id',
    );

    final candidate = (await repository.streamPages().first).candidates.single;

    expect(candidate.mediaType, CatalogMediaType.series);
    expect(
      candidate.poster.uri?.path,
      '/jellyfin/Items/series-1/Images/Primary',
    );
    expect(candidate.poster.uri?.query, 'tag=primary');
    expect(candidate.poster.uri.toString(), isNot(contains('token')));
    expect(candidate.backdrop.aspectRatio, greaterThan(1));
  });

  test('should return typed unauthorized and server failures', () async {
    final unauthorized = JellyfinCatalogRepository(
      client: RecordingHttpClient((request) async => http.Response('', 403)),
      serverUrl: 'https://example.test',
      accessToken: 'token',
      deviceId: 'device',
      userId: 'user-id',
    );
    final serverError = JellyfinCatalogRepository(
      client: RecordingHttpClient((request) async => http.Response('', 503)),
      serverUrl: 'https://example.test',
      accessToken: 'token',
      deviceId: 'device',
      userId: 'user-id',
    );

    expect(
      (await unauthorized.streamPages().first).failure,
      isA<UnauthorizedCatalogFailure>(),
    );
    expect(
      (await serverError.streamPages().first).failure,
      isA<ServerCatalogFailure>(),
    );
  });

  test('should classify an expired catalog token as typed failure', () async {
    final repository = JellyfinCatalogRepository(
      client: RecordingHttpClient((request) async => http.Response('', 401)),
      serverUrl: 'https://example.test',
      accessToken: 'token',
      deviceId: 'device',
      userId: 'user-id',
    );

    expect(
      (await repository.streamPages().first).failure,
      isA<ExpiredCatalogFailure>(),
    );
  });

  test(
    'should classify redirects and invalid certificates as typed failures',
    () async {
      final redirect = JellyfinCatalogRepository(
        client: RecordingHttpClient((request) async => http.Response('', 302)),
        serverUrl: 'https://example.test',
        accessToken: 'token',
        deviceId: 'device',
        userId: 'user-id',
      );
      final certificate = JellyfinCatalogRepository(
        client: RecordingHttpClient((request) async {
          throw const HandshakeException('invalid certificate');
        }),
        serverUrl: 'https://example.test',
        accessToken: 'token',
        deviceId: 'device',
        userId: 'user-id',
      );

      expect(
        (await redirect.streamPages().first).failure,
        isA<RedirectCatalogFailure>(),
      );
      expect(
        (await certificate.streamPages().first).failure,
        isA<InvalidCertificateCatalogFailure>(),
      );
    },
  );

  test(
    'should emit the first usable page before traversing a large library',
    () async {
      var requests = 0;
      final repository = JellyfinCatalogRepository(
        client: RecordingHttpClient((request) async {
          requests++;
          return _jsonResponse({
            'Items': <Map<String, Object?>>[_movieJson()],
            'TotalRecordCount': 2000,
          });
        }),
        serverUrl: 'https://example.test',
        accessToken: 'token',
        deviceId: 'device',
        userId: 'user-id',
      );

      final page = await repository.streamPages().first;

      expect(page.candidates, isNotEmpty);
      expect(requests, 1);
      expect(page.hasMore, isTrue);
    },
  );

  test('should increment StartIndex by the returned item count', () async {
    var call = 0;
    final repository = JellyfinCatalogRepository(
      client: RecordingHttpClient((request) async {
        call++;
        final item = <String, Object?>{..._movieJson(), 'Id': 'movie-$call'};
        return _jsonResponse({
          'Items': <Map<String, Object?>>[item],
          'StartIndex': call - 1,
          'TotalRecordCount': 2,
        });
      }),
      serverUrl: 'https://example.test',
      accessToken: 'token',
      deviceId: 'device',
      userId: 'user-id',
    );

    final pages = await repository.streamPages().take(2).toList();

    expect(pages, hasLength(2));
    expect(repository.client, isA<RecordingHttpClient>());
    final requests = (repository.client as RecordingHttpClient).requests;
    expect(requests[0].url.queryParameters['startIndex'], '0');
    expect(requests[1].url.queryParameters['startIndex'], '1');
  });

  test('should emit page one before awaiting a delayed later page', () async {
    final secondPage = Completer<http.Response>();
    var call = 0;
    final repository = JellyfinCatalogRepository(
      client: RecordingHttpClient((request) async {
        call++;
        if (call == 1) {
          return _jsonResponse({
            'Items': <Map<String, Object?>>[_movieJson()],
            'StartIndex': 0,
            'TotalRecordCount': 2,
          });
        }
        return secondPage.future;
      }),
      serverUrl: 'https://example.test',
      accessToken: 'token',
      deviceId: 'device',
      userId: 'user-id',
    );
    final iterator = StreamIterator(repository.streamPages());

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current.candidates, isNotEmpty);
    final secondMove = iterator.moveNext();
    await Future<void>.delayed(Duration.zero);
    expect(call, 2);
    secondPage.complete(
      _jsonResponse({
        'Items': <Map<String, Object?>>[
          <String, Object?>{..._movieJson(), 'Id': 'movie-2'},
        ],
        'StartIndex': 1,
        'TotalRecordCount': 2,
      }),
    );
    expect(await secondMove, isTrue);
    await iterator.cancel();
  });

  test('should consume a 2,000-item library in bounded pages', () async {
    final client = RecordingHttpClient((request) async {
      final start = int.parse(request.url.queryParameters['startIndex'] ?? '0');
      return _jsonResponse({
        'Items': List<Map<String, Object?>>.generate(
          50,
          (offset) => <String, Object?>{
            ..._movieJson(),
            'Id': 'movie-${start + offset}',
          },
        ),
        'StartIndex': start,
        'TotalRecordCount': 2000,
      });
    });
    final repository = JellyfinCatalogRepository(
      client: client,
      serverUrl: 'https://example.test',
      accessToken: 'token',
      deviceId: 'device',
      userId: 'user-id',
    );

    final pages = await repository.streamPages().toList();
    final candidates = pages.expand((page) => page.candidates).toList();

    expect(candidates, hasLength(2000));
    expect(
      candidates.map((candidate) => candidate.id).toSet(),
      hasLength(2000),
    );
    expect(client.requests, hasLength(40));
    expect(client.requests.last.url.queryParameters['startIndex'], '1950');
    expect(
      client.requests.every(
        (request) => request.url.queryParameters['limit'] == '50',
      ),
      isTrue,
    );
  });

  test('should mark a page partial when a media item is malformed', () async {
    final client = RecordingHttpClient(
      (request) async => _jsonResponse({
        'Items': <Map<String, Object?>>[
          _movieJson(),
          <String, Object?>{'Type': 'Movie', 'Name': 'Missing id'},
        ],
        'TotalRecordCount': 2,
      }),
    );
    final repository = JellyfinCatalogRepository(
      client: client,
      serverUrl: 'https://example.test',
      accessToken: 'token',
      deviceId: 'device',
      userId: 'user-id',
    );

    final page = await repository.streamPages().first;

    expect(page.candidates, hasLength(1));
    expect(page.failure, isA<PartialCatalogFailure>());
  });

  test('should report an empty accessible library', () async {
    final repository = JellyfinCatalogRepository(
      client: RecordingHttpClient(
        (request) async => _jsonResponse({
          'Items': <Map<String, Object?>>[],
          'TotalRecordCount': 0,
        }),
      ),
      serverUrl: 'https://example.test',
      accessToken: 'token',
      deviceId: 'device',
      userId: 'user-id',
    );

    final page = await repository.streamPages().first;

    expect(page.failure, isA<NoAccessibleLibraryFailure>());
  });

  test(
    'should report no match when an active filter finds an empty library',
    () async {
      final repository = JellyfinCatalogRepository(
        client: RecordingHttpClient(
          (request) async => _jsonResponse({
            'Items': <Map<String, Object?>>[],
            'TotalRecordCount': 0,
          }),
        ),
        serverUrl: 'https://example.test',
        accessToken: 'token',
        deviceId: 'device',
        userId: 'user-id',
      );

      final page = await repository
          .streamPages(
            filter: const CatalogFilter(
              mediaTypes: <CatalogMediaType>{CatalogMediaType.movie},
            ),
          )
          .first;

      expect(page.failure, isA<NoCatalogMatchFailure>());
    },
  );

  test('should deduplicate overlapping IDs across pages', () async {
    var call = 0;
    final repository = JellyfinCatalogRepository(
      client: RecordingHttpClient((request) async {
        call++;
        return _jsonResponse({
          'Items': <Map<String, Object?>>[
            <String, Object?>{
              ..._movieJson(),
              'Id': call == 1 ? 'same' : 'same',
            },
          ],
          'StartIndex': call - 1,
          'TotalRecordCount': 2,
        });
      }),
      serverUrl: 'https://example.test',
      accessToken: 'token',
      deviceId: 'device',
      userId: 'user-id',
    );

    final pages = await repository.streamPages().take(2).toList();

    expect(pages.expand((page) => page.candidates), hasLength(1));
  });

  test('should stop an empty remaining page with a partial failure', () async {
    final client = RecordingHttpClient(
      (request) async => _jsonResponse({
        'Items': <Object?>[],
        'StartIndex': 0,
        'TotalRecordCount': 51,
      }),
    );
    final repository = JellyfinCatalogRepository(
      client: client,
      serverUrl: 'https://example.test',
      accessToken: 'token',
      deviceId: 'device',
      userId: 'user-id',
    );

    final page = await repository.streamPages().first;

    expect(page.candidates, isEmpty);
    expect(page.hasMore, isFalse);
    expect(page.failure, isA<PartialCatalogFailure>());
    expect(client.requests, hasLength(1));
  });

  test(
    'should advance by raw item count when malformed entries are present',
    () async {
      var call = 0;
      final client = RecordingHttpClient((request) async {
        call++;
        return call == 1
            ? _jsonResponse({
                'Items': <Object?>[_movieJson(), 'malformed'],
                'StartIndex': 0,
                'TotalRecordCount': 3,
              })
            : _jsonResponse({
                'Items': <Map<String, Object?>>[
                  <String, Object?>{..._movieJson(), 'Id': 'movie-3'},
                ],
                'StartIndex': 2,
                'TotalRecordCount': 3,
              });
      });
      final repository = JellyfinCatalogRepository(
        client: client,
        serverUrl: 'https://example.test',
        accessToken: 'token',
        deviceId: 'device',
        userId: 'user-id',
      );

      final pages = await repository.streamPages().take(2).toList();

      expect(pages, hasLength(2));
      expect(pages.first.failure, isA<PartialCatalogFailure>());
      expect(client.requests[1].url.queryParameters['startIndex'], '2');
    },
  );

  test('should classify malformed roots and totals as incompatible', () async {
    final malformedRoot = JellyfinCatalogRepository(
      client: RecordingHttpClient(
        (request) async => http.Response(jsonEncode(<Object?>[]), 200),
      ),
      serverUrl: 'https://example.test',
      accessToken: 'token',
      deviceId: 'device',
      userId: 'user-id',
    );
    final malformedTotal = JellyfinCatalogRepository(
      client: RecordingHttpClient(
        (request) async => _jsonResponse({
          'Items': <Map<String, Object?>>[],
          'TotalRecordCount': 'unknown',
        }),
      ),
      serverUrl: 'https://example.test',
      accessToken: 'token',
      deviceId: 'device',
      userId: 'user-id',
    );

    expect(
      (await malformedRoot.streamPages().first).failure,
      isA<IncompatibleCatalogFailure>(),
    );
    expect(
      (await malformedTotal.streamPages().first).failure,
      isA<IncompatibleCatalogFailure>(),
    );
  });

  test(
    'should report no match when an active filter excludes all items',
    () async {
      final repository = JellyfinCatalogRepository(
        client: RecordingHttpClient(
          (request) async => _jsonResponse({
            'Items': <Map<String, Object?>>[_movieJson()],
            'TotalRecordCount': 1,
          }),
        ),
        serverUrl: 'https://example.test',
        accessToken: 'token',
        deviceId: 'device',
        userId: 'user-id',
      );

      final page = await repository
          .streamPages(filter: const CatalogFilter(minimumRuntimeMinutes: 100))
          .first;

      expect(page.candidates, isEmpty);
      expect(page.failure, isA<NoCatalogMatchFailure>());
    },
  );

  test(
    'should classify transport failures without leaking exceptions',
    () async {
      final failures = <Object>[
        const SocketException('offline'),
        TimeoutException('slow'),
        http.ClientException('client failure'),
      ];

      for (final failure in failures) {
        final repository = JellyfinCatalogRepository(
          client: RecordingHttpClient((request) async {
            throw failure;
          }),
          serverUrl: 'https://example.test',
          accessToken: 'token',
          deviceId: 'device',
          userId: 'user-id',
        );

        final page = await repository.streamPages().first;

        expect(page.failure, isA<UnreachableCatalogFailure>());
      }
    },
  );

  test(
    'should retain the first page before a typed later-page failure',
    () async {
      var call = 0;
      final repository = JellyfinCatalogRepository(
        client: RecordingHttpClient((request) async {
          call++;
          if (call == 1) {
            return _jsonResponse({
              'Items': <Map<String, Object?>>[_movieJson()],
              'StartIndex': 0,
              'TotalRecordCount': 2,
            });
          }
          return http.Response('', 503);
        }),
        serverUrl: 'https://example.test',
        accessToken: 'token',
        deviceId: 'device',
        userId: 'user-id',
      );

      final pages = await repository.streamPages().toList();

      expect(pages.first.candidates, hasLength(1));
      expect(pages.last.failure, isA<ServerCatalogFailure>());
    },
  );

  test('should push safe filter constraints to the server query', () async {
    final client = RecordingHttpClient(
      (request) async => _jsonResponse({
        'Items': <Map<String, Object?>>[_movieJson()],
        'TotalRecordCount': 1,
      }),
    );
    final repository = JellyfinCatalogRepository(
      client: client,
      serverUrl: 'https://example.test',
      accessToken: 'token',
      deviceId: 'device',
      userId: 'user-id',
    );

    await repository
        .streamPages(
          filter: const CatalogFilter(
            mediaTypes: <CatalogMediaType>{CatalogMediaType.movie},
            minimumRuntimeMinutes: 60,
            maximumRuntimeMinutes: 120,
            minimumCommunityRating: 7,
            minimumCriticRating: 6,
            maximumCriticRating: 9,
            genres: <String>{'Drama', 'Comedy'},
            decades: <int>{2020, 2010},
          ),
        )
        .first;
    final query = client.requests.single.url.queryParameters;

    expect(query['includeItemTypes'], 'Movie');
    expect(query['minCommunityRating'], '7.0');
    expect(query['minCriticRating'], '6.0');
    expect(query.containsKey('minRuntime'), isFalse);
    expect(query.containsKey('maxRuntime'), isFalse);
    expect(query.containsKey('maxCommunityRating'), isFalse);
    expect(query.containsKey('maxCriticRating'), isFalse);
    expect(query['genres'], 'Comedy|Drama');
    final years = query['years']!.split(',');
    expect(years, containsAll(<String>['2010', '2019', '2020', '2029']));
    expect(years, isNot(contains('2030')));
  });

  test(
    'should classify malformed nested metadata as partial without throwing',
    () async {
      final repository = JellyfinCatalogRepository(
        client: RecordingHttpClient(
          (request) async => _jsonResponse({
            'Items': <Object?>[
              <String, Object?>{
                ..._movieJson(),
                'UserData': <String, Object?>{'Played': 'invalid'},
              },
              'not-an-item',
            ],
            'TotalRecordCount': 2,
          }),
        ),
        serverUrl: 'https://example.test',
        accessToken: 'token',
        deviceId: 'device',
        userId: 'user-id',
      );

      final page = await repository.streamPages().first;

      expect(page.candidates, hasLength(1));
      expect(page.failure, isA<PartialCatalogFailure>());
    },
  );

  test('should map date created and user filter metadata', () async {
    final client = RecordingHttpClient(
      (request) async => _jsonResponse({
        'Items': <Map<String, Object?>>[
          <String, Object?>{
            ..._movieJson(),
            'DateCreated': '2026-08-01T10:20:30Z',
            'UserData': <String, Object?>{'Played': false, 'IsFavorite': true},
          },
        ],
        'TotalRecordCount': 1,
      }),
    );
    final repository = JellyfinCatalogRepository(
      client: client,
      serverUrl: 'https://example.test',
      accessToken: 'token',
      deviceId: 'device',
      userId: 'user-id',
    );

    final candidate = (await repository.streamPages().first).candidates.single;

    expect(candidate.dateCreated, DateTime.parse('2026-08-01T10:20:30Z'));
    expect(candidate.watched, isFalse);
    expect(candidate.favorite, isTrue);
  });

  test('should treat malformed date created metadata as partial', () async {
    final repository = JellyfinCatalogRepository(
      client: RecordingHttpClient(
        (request) async => _jsonResponse({
          'Items': <Map<String, Object?>>[
            <String, Object?>{..._movieJson(), 'DateCreated': 'not-a-date'},
          ],
          'TotalRecordCount': 1,
        }),
      ),
      serverUrl: 'https://example.test',
      accessToken: 'token',
      deviceId: 'device',
      userId: 'user-id',
    );

    final page = await repository.streamPages().first;

    expect(page.candidates.single.dateCreated, isNull);
    expect(page.failure, isA<PartialCatalogFailure>());
  });

  test(
    'should push search and supported filters to the server query',
    () async {
      final client = RecordingHttpClient(
        (request) async => _jsonResponse({
          'Items': <Map<String, Object?>>[_movieJson()],
          'TotalRecordCount': 1,
        }),
      );
      final repository = JellyfinCatalogRepository(
        client: client,
        serverUrl: 'https://example.test',
        accessToken: 'token',
        deviceId: 'device',
        userId: 'user-id',
      );

      await repository
          .streamPages(
            filter: const CatalogFilter(
              searchTerm: 'candy',
              watched: true,
              favorite: true,
              officialRatings: <String>{'R', 'PG-13'},
              seriesStatuses: <CatalogSeriesStatus>{
                CatalogSeriesStatus.continuing,
                CatalogSeriesStatus.ended,
              },
            ),
          )
          .first;

      final query = client.requests.single.url.queryParameters;
      expect(query['searchTerm'], 'candy');
      expect(query['isPlayed'], 'true');
      expect(query['isFavorite'], 'true');
      expect(query['officialRatings'], 'PG-13|R');
      expect(query['seriesStatus'], 'Continuing,Ended');
      expect(query['filters'], 'IsNotFolder');
    },
  );

  test(
    'should map sort and added window constraints to the server query',
    () async {
      final client = RecordingHttpClient(
        (request) async => _jsonResponse({
          'Items': <Map<String, Object?>>[_movieJson()],
          'TotalRecordCount': 1,
        }),
      );
      final repository = JellyfinCatalogRepository(
        client: client,
        serverUrl: 'https://example.test',
        accessToken: 'token',
        deviceId: 'device',
        userId: 'user-id',
        now: () => DateTime.utc(2026, 8, 11, 12),
      );

      await repository
          .streamPages(
            filter: const CatalogFilter(
              addedWithin: CatalogAddedWindow.sevenDays,
              sort: CatalogSort.recentlyAdded,
            ),
          )
          .first;

      final query = client.requests.single.url.queryParameters;
      expect(query['sortBy'], 'DateCreated');
      expect(query['sortOrder'], 'Descending');
      expect(query.containsKey('minDateCreated'), isFalse);
    },
  );

  test(
    'should map every supported sort to its Jellyfin query values',
    () async {
      for (final entry in <CatalogSort, List<String?>>{
        CatalogSort.defaultOrder: <String?>[null, null],
        CatalogSort.recentlyAdded: <String?>['DateCreated', 'Descending'],
        CatalogSort.title: <String?>['SortName', 'Ascending'],
        CatalogSort.releaseYear: <String?>['ProductionYear', 'Descending'],
        CatalogSort.communityRating: <String?>['CommunityRating', 'Descending'],
        CatalogSort.runtime: <String?>['Runtime', 'Ascending'],
      }.entries) {
        final client = RecordingHttpClient(
          (request) async => _jsonResponse({
            'Items': <Map<String, Object?>>[_movieJson()],
            'TotalRecordCount': 1,
          }),
        );
        final repository = JellyfinCatalogRepository(
          client: client,
          serverUrl: 'https://example.test',
          accessToken: 'token',
          deviceId: 'device',
          userId: 'user-id',
        );

        await repository
            .streamPages(filter: CatalogFilter(sort: entry.key))
            .first;

        final query = client.requests.single.url.queryParameters;
        expect(query['sortBy'], entry.value[0]);
        expect(query['sortOrder'], entry.value[1]);
      }
    },
  );

  test(
    'should capture the clock once while refining an added window across pages',
    () async {
      var clockCalls = 0;
      var requestCount = 0;
      final client = RecordingHttpClient((request) async {
        requestCount++;
        final startIndex = int.parse(
          request.url.queryParameters['startIndex']!,
        );
        return _jsonResponse({
          'Items': <Map<String, Object?>>[
            <String, Object?>{
              ..._movieJson(),
              'Id': 'movie-$requestCount',
              'DateCreated': startIndex == 0
                  ? '2026-08-04T11:59:59Z'
                  : '2026-08-04T12:00:00Z',
            },
          ],
          'StartIndex': startIndex,
          'TotalRecordCount': 2,
        });
      });
      final repository = JellyfinCatalogRepository(
        client: client,
        serverUrl: 'https://example.test',
        accessToken: 'token',
        deviceId: 'device',
        userId: 'user-id',
        now: () {
          clockCalls++;
          return DateTime.utc(2026, 8, 11, 12);
        },
      );

      final pages = await repository
          .streamPages(
            filter: const CatalogFilter(
              addedWithin: CatalogAddedWindow.sevenDays,
            ),
          )
          .toList();
      final candidates = pages.expand((page) => page.candidates).toList();

      expect(candidates.map((candidate) => candidate.id), <String>['movie-2']);
      expect(clockCalls, 1);
    },
  );
}

Map<String, Object?> _movieJson() => <String, Object?>{
  'Id': 'movie-1',
  'Name': 'Candy Movie',
  'Type': 'Movie',
  'ProductionYear': 2024,
  'RunTimeTicks': 43200000000,
  'Genres': <String>['Drama'],
  'CommunityRating': 8.2,
  'CriticRating': 7.4,
  'OfficialRating': 'PG-13',
  'Overview': 'A bright story.',
  'UserData': <String, Object?>{'Played': true, 'IsFavorite': true},
  'ImageTags': <String, String>{'Primary': 'primary-tag'},
  'BackdropImageTags': <String>['backdrop-tag'],
};

Map<String, Object?> _seriesJson() => <String, Object?>{
  'Id': 'series-1',
  'Name': 'Candy Series',
  'Type': 'Series',
  'ProductionYear': 2020,
  'ImageTags': <String, String>{'Primary': 'primary'},
  'BackdropImageTags': <String>['backdrop'],
  'UserData': <String, Object?>{'Played': false, 'IsFavorite': false},
};

Map<String, Object?> _movieWithoutImagesJson() {
  final item = _movieJson();
  item.remove('ImageTags');
  item.remove('BackdropImageTags');
  return item;
}

Map<String, Object?> _episodeJson() => <String, Object?>{
  'Id': 'episode-1',
  'Name': 'Episode',
  'Type': 'Episode',
};

http.Response _jsonResponse(Map<String, Object?> body) => http.Response(
  jsonEncode(body),
  200,
  headers: <String, String>{'content-type': 'application/json'},
);
