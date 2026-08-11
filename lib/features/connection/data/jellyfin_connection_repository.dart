import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:jellyfin_picker/core/network/media_browser_authorization.dart';
import 'package:jellyfin_picker/features/connection/data/session_store.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/connection_request.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/stored_session.dart';
import 'package:jellyfin_picker/features/connection/domain/failures/connection_failure.dart';
import 'package:jellyfin_picker/features/connection/domain/repositories/connection_repository.dart';
import 'package:jellyfin_picker/features/connection/domain/server_url_policy.dart';

/// Jellyfin HTTP boundary with injectable transport and persistence.
final class JellyfinConnectionRepository implements ConnectionRepository {
  JellyfinConnectionRepository({
    required this.client,
    required this.sessionStore,
    required this.deviceIdProvider,
    this.timeout = const Duration(seconds: 10),
  });

  final http.Client client;
  final SessionStore sessionStore;
  final DeviceIdProvider deviceIdProvider;
  final Duration timeout;

  void close() => client.close();

  @override
  Future<ConnectionResult> connect(ConnectionRequest request) async {
    late final Uri baseUrl;
    try {
      baseUrl = ServerUrlPolicy.normalize(
        request.baseUrl,
        allowPrivateHttp: request.allowPrivateHttp,
      );
    } on PrivateHttpConfirmationRequiredFailure {
      return PrivateHttpConfirmationResult(request.baseUrl.trim());
    } on ConnectionFailure catch (failure) {
      return ConnectionFailureResult(failure);
    }

    try {
      final String deviceId;
      try {
        deviceId = await deviceIdProvider.loadOrCreate();
      } on Object catch (_) {
        return const ConnectionFailureResult(StorageFailure());
      }
      final publicInfoResponse = await _send(
        'GET',
        _endpoint(baseUrl, 'System/Info/Public'),
      );
      final publicInfo = _parseServerInfo(publicInfoResponse);
      final authResponse = await _send(
        'POST',
        _endpoint(baseUrl, 'Users/AuthenticateByName'),
        headers: _headers(deviceId),
        body: jsonEncode(<String, String>{
          'Username': request.username,
          'Pw': request.password,
        }),
      );
      if (authResponse.statusCode == 401 || authResponse.statusCode == 403) {
        return const ConnectionFailureResult(InvalidCredentialsFailure());
      }
      if (authResponse.statusCode < 200 || authResponse.statusCode >= 300) {
        return ConnectionFailureResult(
          authResponse.statusCode >= 500
              ? const ServerFailure()
              : const IncompatibleServerFailure(),
        );
      }
      final auth = _decodeObject(authResponse.body);
      final token = _requiredString(auth, 'AccessToken');
      final user = _requiredObject(auth, 'User');
      final userId = _requiredString(user, 'Id');
      final username = _requiredString(user, 'Name');
      final session = StoredSession(
        serverUrl: baseUrl.toString(),
        accessToken: token,
        userId: userId,
        username: username,
        deviceId: deviceId,
        serverName: publicInfo.serverName,
        serverVersion: publicInfo.version,
      );
      try {
        await sessionStore.writeSession(session);
      } on Object catch (_) {
        return const ConnectionFailureResult(StorageFailure());
      }
      return ConnectionSuccess(session);
    } on ConnectionFailure catch (failure) {
      return ConnectionFailureResult(failure);
    } on Object catch (error) {
      return ConnectionFailureResult(_mapError(error));
    }
  }

  @override
  Future<SessionRestoreResult> restoreSession() async {
    final StoredSession? session;
    try {
      session = await sessionStore.readSession();
    } on Object catch (_) {
      return const SessionRestoreFailure(StorageFailure());
    }
    if (session == null) {
      return const NoStoredSession();
    }
    try {
      final baseUrl = ServerUrlPolicy.normalize(
        session.serverUrl,
        allowPrivateHttp: true,
      );
      final response = await _send(
        'GET',
        _endpoint(baseUrl, 'System/Info'),
        headers: _headers(session.deviceId, token: session.accessToken),
      );
      if (response.statusCode == 401 || response.statusCode == 403) {
        await _clearExpiredSession(session, baseUrl);
        return const SessionRestoreFailure(ExpiredSessionFailure());
      }
      _parseServerInfo(response);
      return SessionRestored(session);
    } on ConnectionFailure catch (failure) {
      return SessionRestoreFailure(failure);
    } on Object catch (error) {
      return SessionRestoreFailure(_mapError(error));
    }
  }

  @override
  Future<LogoutResult> logout() async {
    final StoredSession? session;
    try {
      session = await sessionStore.readSession();
    } on Object catch (_) {
      try {
        await sessionStore.clearSession();
      } on Object catch (_) {}
      return const LogoutStorageFailureResult(StorageFailure());
    }
    var remoteSucceeded = true;
    var storageFailed = false;
    if (session != null) {
      try {
        final baseUrl = ServerUrlPolicy.normalize(
          session.serverUrl,
          allowPrivateHttp: true,
        );
        final response = await _send(
          'POST',
          _endpoint(baseUrl, 'Sessions/Logout'),
          headers: _headers(session.deviceId, token: session.accessToken),
        );
        remoteSucceeded =
            response.statusCode >= 200 && response.statusCode < 300;
      } on Object catch (_) {
        remoteSucceeded = false;
      } finally {
        try {
          await sessionStore.clearSession();
        } on Object catch (_) {
          storageFailed = true;
        }
      }
    } else {
      try {
        await sessionStore.clearSession();
      } on Object catch (_) {
        storageFailed = true;
      }
    }
    if (storageFailed) {
      return const LogoutStorageFailureResult(StorageFailure());
    }
    return LogoutCompleted(remoteSucceeded: remoteSucceeded);
  }

  Future<void> _clearExpiredSession(StoredSession session, Uri baseUrl) async {
    try {
      await _send(
        'POST',
        _endpoint(baseUrl, 'Sessions/Logout'),
        headers: _headers(session.deviceId, token: session.accessToken),
      );
    } on Object catch (_) {
      // The local clear in finally is the security boundary; remote logout is
      // best effort because the token has already been rejected.
    } finally {
      try {
        await sessionStore.clearSession();
      } on Object catch (_) {
        throw const StorageFailure();
      }
    }
  }

  ServerInfo _parseServerInfo(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const IncompatibleServerFailure();
      }
      if (response.statusCode >= 300 && response.statusCode < 400) {
        throw const UnsafeRedirectFailure();
      }
      if (response.statusCode >= 500) {
        throw const ServerFailure();
      }
      throw const IncompatibleServerFailure();
    }
    final body = _decodeObject(response.body);
    final product = _requiredString(body, 'ProductName');
    final version = _requiredString(body, 'Version');
    final major = int.tryParse(version.split('.').first);
    if (product.toLowerCase() != 'jellyfin' || major == null || major < 10) {
      throw const IncompatibleServerFailure();
    }
    final serverName = body['ServerName'];
    if (serverName != null && serverName is! String) {
      throw const IncompatibleServerFailure();
    }
    return ServerInfo(version: version, serverName: serverName as String?);
  }

  Map<String, String> _headers(String deviceId, {String? token}) {
    return <String, String>{
      'Authorization': MediaBrowserAuthorization.value(
        deviceId: deviceId,
        token: token,
      ),
      'Content-Type': 'application/json',
    };
  }

  Future<http.Response> _send(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final request = http.Request(method, uri)
      ..followRedirects = false
      ..headers.addAll(headers ?? const <String, String>{});
    if (body != null) {
      request.body = body;
    }
    final response = await client.send(request).timeout(timeout);
    final buffered = await http.Response.fromStream(response);
    if (buffered.statusCode >= 300 && buffered.statusCode < 400) {
      throw const UnsafeRedirectFailure();
    }
    return buffered;
  }

  Uri _endpoint(Uri baseUrl, String endpoint) {
    final joinedPath = <String>[
      baseUrl.path,
      endpoint,
    ].where((part) => part.isNotEmpty).join('/');
    final normalizedPath = joinedPath.startsWith('/')
        ? joinedPath
        : '/$joinedPath';
    return baseUrl.replace(path: normalizedPath);
  }

  Map<String, Object?> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const IncompatibleServerFailure();
    }
    return decoded.map<String, Object?>((key, value) {
      return MapEntry(key.toString(), value);
    });
  }

  String _requiredString(Map<String, Object?> object, String key) {
    final value = object[key];
    if (value is! String || value.isEmpty) {
      throw const IncompatibleServerFailure();
    }
    return value;
  }

  Map<String, Object?> _requiredObject(
    Map<String, Object?> object,
    String key,
  ) {
    final value = object[key];
    if (value is! Map) {
      throw const IncompatibleServerFailure();
    }
    return value.map<String, Object?>((name, content) {
      return MapEntry(name.toString(), content);
    });
  }

  ConnectionFailure _mapError(Object error) {
    return switch (error) {
      HandshakeException() => const InvalidCertificateFailure(),
      SocketException() ||
      TimeoutException() ||
      http.ClientException() => const UnreachableFailure(),
      FormatException() => const IncompatibleServerFailure(),
      _ => const UnreachableFailure(),
    };
  }
}

final class ServerInfo {
  const ServerInfo({required this.version, this.serverName});

  final String version;
  final String? serverName;
}
