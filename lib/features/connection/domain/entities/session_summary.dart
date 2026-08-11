import 'package:jellyfin_picker/features/connection/domain/entities/stored_session.dart';

/// Non-secret session details safe for presentation state.
final class SessionSummary {
  const SessionSummary({
    required this.serverUrl,
    required this.userId,
    required this.username,
    this.serverName,
    this.serverVersion,
  });

  factory SessionSummary.fromStoredSession(StoredSession session) {
    return SessionSummary(
      serverUrl: session.serverUrl,
      userId: session.userId,
      username: session.username,
      serverName: session.serverName,
      serverVersion: session.serverVersion,
    );
  }

  final String serverUrl;
  final String userId;
  final String username;
  final String? serverName;
  final String? serverVersion;
}
