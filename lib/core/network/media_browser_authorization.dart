/// Builds the modern Jellyfin MediaBrowser authorization header.
abstract final class MediaBrowserAuthorization {
  static String value({required String deviceId, String? token}) {
    final header = StringBuffer(
      'MediaBrowser Client="Jellyfin Picker", '
      'Device="Jellyfin Picker", '
      'DeviceId="$deviceId", Version="1.0.0"',
    );
    if (token != null) {
      header.write(', Token="$token"');
    }
    return header.toString();
  }
}
