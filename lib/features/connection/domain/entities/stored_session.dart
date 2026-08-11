/// The minimum session data needed to restore a Jellyfin connection.
final class StoredSession {
  const StoredSession({
    required this.serverUrl,
    required this.accessToken,
    required this.userId,
    required this.username,
    required this.deviceId,
    this.serverName,
    this.serverVersion,
  });

  final String serverUrl;
  final String accessToken;
  final String userId;
  final String username;
  final String deviceId;
  final String? serverName;
  final String? serverVersion;
}
