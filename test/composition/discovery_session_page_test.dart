import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:jellyfin_picker/composition/discovery_session_page.dart';
import 'package:jellyfin_picker/core/theme/candy_theme.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/stored_session.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_mode.dart';
import 'package:jellyfin_picker/features/discovery/domain/entities/discovery_snapshot.dart';
import 'package:jellyfin_picker/features/discovery/domain/repositories/discovery_store.dart';
import 'package:jellyfin_picker/l10n/generated/app_localizations.dart';

import '../shared/discovery_robot.dart';
import '../shared/fake_discovery_store.dart';
import '../shared/recording_http_client.dart';

void main() {
  testWidgets(
    'should use suggestions initially and a random Jellyfin batch in shuffle',
    (tester) async {
      final client = RecordingHttpClient((request) async {
        if (request.url.path == '/UserViews') {
          return _jsonResponse({
            'Items': <Map<String, Object?>>[],
            'TotalRecordCount': 0,
          });
        }
        if (request.url.path == '/Items/Filters' ||
            request.url.path == '/Items/Filters2') {
          return _jsonResponse(<String, Object?>{});
        }
        if (request.url.path == '/Items/Suggestions') {
          return _jsonResponse({
            'Items': <Map<String, Object?>>[_movie('suggested')],
            'StartIndex': 0,
            'TotalRecordCount': 1,
          });
        }
        if (request.url.path == '/Items') {
          return _jsonResponse({
            'Items': <Map<String, Object?>>[_movie('random')],
            'StartIndex': 0,
            'TotalRecordCount': 1,
          });
        }
        return http.Response('', 404);
      });
      final robot = DiscoveryRobot(tester);

      await tester.pumpWidget(_app(client));
      await tester.pumpAndSettle();

      robot.expectCandidateVisible('Suggested');
      expect(
        client.requests.map((request) => request.url.path),
        contains('/Items/Suggestions'),
      );

      await robot.openShuffle();
      await tester.pumpAndSettle();

      expect(
        client.requests.any(
          (request) =>
              request.url.path == '/Items' &&
              request.url.queryParameters['sortBy'] == 'Random',
        ),
        isTrue,
      );
    },
  );

  testWidgets('should refill an exhausted random batch with exclusions', (
    tester,
  ) async {
    var randomRequests = 0;
    final client = RecordingHttpClient((request) async {
      if (request.url.path == '/UserViews') {
        return _jsonResponse({
          'Items': <Map<String, Object?>>[],
          'TotalRecordCount': 0,
        });
      }
      if (request.url.path == '/Items/Filters' ||
          request.url.path == '/Items/Filters2') {
        return _jsonResponse(<String, Object?>{});
      }
      if (request.url.path == '/Items') {
        randomRequests++;
        final id = randomRequests == 1 ? 'rejected' : 'fresh';
        return _jsonResponse({
          'Items': <Map<String, Object?>>[_movie(id)],
          'StartIndex': 0,
          'TotalRecordCount': 1,
        });
      }
      return http.Response('', 404);
    });
    final store = ImmediateDiscoveryStore()
      ..snapshot = const DiscoverySnapshot(
        mode: DiscoveryMode.shuffle,
        rejectedIds: <String>{'rejected'},
      );
    final robot = DiscoveryRobot(tester);

    await tester.pumpWidget(_app(client, discoveryStore: store));
    await tester.pumpAndSettle();
    await robot.reveal();
    await tester.pumpAndSettle();

    final randomCalls = client.requests
        .where((request) => request.url.path == '/Items')
        .toList(growable: false);
    expect(randomCalls, hasLength(2));
    expect(
      randomCalls.last.url.queryParameters['excludeItemIds'],
      contains('rejected'),
    );

    await robot.reveal();
    await tester.pumpAndSettle();
    robot.expectCandidateVisible('Fresh');
  });

  testWidgets('should restore a bounded local shortlist in shuffle', (
    tester,
  ) async {
    final client = RecordingHttpClient((request) async {
      if (request.url.path == '/UserViews') {
        return _jsonResponse({
          'Items': <Map<String, Object?>>[],
          'TotalRecordCount': 0,
        });
      }
      if (request.url.path == '/Items/Filters' ||
          request.url.path == '/Items/Filters2') {
        return _jsonResponse(<String, Object?>{});
      }
      if (request.url.path == '/Items') {
        return _jsonResponse({
          'Items': <Map<String, Object?>>[_movie('liked')],
          'StartIndex': 0,
          'TotalRecordCount': 1,
        });
      }
      return http.Response('', 404);
    });
    final store = ImmediateDiscoveryStore()
      ..snapshot = const DiscoverySnapshot(
        mode: DiscoveryMode.shuffle,
        likedIds: <String>{'liked'},
      );
    final robot = DiscoveryRobot(tester);

    await tester.pumpWidget(_app(client, discoveryStore: store));
    await tester.pumpAndSettle();

    final request = client.requests.singleWhere(
      (request) => request.url.path == '/Items',
    );
    expect(request.url.queryParameters['ids'], 'liked');
    expect(request.url.queryParameters, isNot(contains('excludeItemIds')));

    await robot.reveal();
    await tester.pumpAndSettle();
    robot.expectCandidateVisible('Liked');
  });
}

Widget _app(http.Client client, {DiscoveryStore? discoveryStore}) =>
    MaterialApp(
      theme: buildCandyTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DiscoverySessionPage(
        session: const StoredSession(
          serverUrl: 'https://example.test',
          accessToken: 'token',
          userId: 'user-id',
          username: 'alice',
          deviceId: 'device-id',
        ),
        client: client,
        discoveryStore: discoveryStore ?? ImmediateDiscoveryStore(),
      ),
    );

Map<String, Object?> _movie(String id) => <String, Object?>{
  'Id': id,
  'Name': switch (id) {
    'suggested' => 'Suggested',
    'fresh' => 'Fresh',
    'liked' => 'Liked',
    _ => 'Random',
  },
  'Type': 'Movie',
  'ProductionYear': 2024,
  'RunTimeTicks': 36000000000,
  'Genres': <String>['Drama'],
  'UserData': <String, Object?>{'Played': false, 'IsFavorite': false},
};

http.Response _jsonResponse(Object value) => http.Response(
  jsonEncode(value),
  200,
  headers: <String, String>{'content-type': 'application/json'},
);
