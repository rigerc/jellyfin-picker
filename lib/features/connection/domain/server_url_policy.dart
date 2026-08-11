import 'package:jellyfin_picker/features/connection/domain/failures/connection_failure.dart';

/// Normalizes server addresses and applies the transport safety policy.
abstract final class ServerUrlPolicy {
  static Uri normalize(String rawUrl, {bool allowPrivateHttp = false}) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      throw const InvalidServerUrlFailure();
    }

    final candidate = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final parsed = Uri.tryParse(candidate);
    if (parsed == null || parsed.host.isEmpty || parsed.userInfo.isNotEmpty) {
      throw const InvalidServerUrlFailure();
    }
    if (parsed.query.isNotEmpty || parsed.fragment.isNotEmpty) {
      throw const InvalidServerUrlFailure();
    }

    final scheme = parsed.scheme.toLowerCase();
    if (scheme != 'https' && scheme != 'http') {
      throw const InvalidServerUrlFailure();
    }
    if (scheme == 'http') {
      if (!_isPrivateLanHost(parsed.host)) {
        throw const PublicHttpFailure();
      }
      if (!allowPrivateHttp) {
        throw const PrivateHttpConfirmationRequiredFailure();
      }
    }

    final path = parsed.path.replaceFirst(RegExp(r'/+$'), '');
    return Uri(
      scheme: scheme,
      host: parsed.host,
      port: parsed.port,
      path: path,
    );
  }

  static bool _isPrivateLanHost(String host) {
    final normalizedHost = host.toLowerCase();
    if (normalizedHost == 'localhost' ||
        normalizedHost == '::1' ||
        normalizedHost.endsWith('.local')) {
      return true;
    }
    if (normalizedHost.contains(':')) {
      return normalizedHost.startsWith('fc') ||
          normalizedHost.startsWith('fd') ||
          normalizedHost.startsWith('fe80');
    }

    final octets = normalizedHost.split('.');
    if (octets.length != 4) {
      return false;
    }
    final values = octets.map(int.tryParse).toList();
    if (values.any((value) => value == null || value < 0 || value > 255)) {
      return false;
    }
    final first = values[0] ?? -1;
    final second = values[1] ?? -1;
    return first == 127 ||
        first == 10 ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 168) ||
        (first == 169 && second == 254);
  }
}
