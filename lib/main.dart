import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:jellyfin_picker/app.dart';
import 'package:jellyfin_picker/composition/discovery_session_page.dart';
import 'package:jellyfin_picker/core/navigation/app_router.dart';
import 'package:jellyfin_picker/features/connection/data/flutter_secure_session_store.dart';
import 'package:jellyfin_picker/features/connection/data/jellyfin_connection_repository.dart';

void main() {
  final storage = FlutterSecureStorage();
  final keyValueStore = FlutterSecureKeyValueStore(storage);
  final client = http.Client();
  final repository = JellyfinConnectionRepository(
    client: client,
    sessionStore: FlutterSecureSessionStore(keyValueStore),
    deviceIdProvider: SecureDeviceIdProvider(keyValueStore),
  );
  runApp(
    JellyfinPickerApp(
      router: buildAppRouter(
        connectionRepository: repository,
        authenticatedBuilder: (context, session) => DiscoverySessionPage(
          session: session,
          client: client,
          onReconnect: () => context.go(AppRoutePaths.connection),
        ),
      ),
      onDispose: repository.close,
    ),
  );
}
