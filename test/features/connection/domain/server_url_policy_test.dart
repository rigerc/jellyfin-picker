import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/features/connection/domain/server_url_policy.dart';
import 'package:jellyfin_picker/features/connection/domain/failures/connection_failure.dart';

void main() {
  test('should default to HTTPS when a scheme is omitted', () {
    final normalized = ServerUrlPolicy.normalize('example.test/jellyfin');

    expect(normalized.toString(), 'https://example.test/jellyfin');
  });

  test('should preserve a reverse proxy path when a URL is normalized', () {
    final normalized = ServerUrlPolicy.normalize(
      'https://example.test/jellyfin/',
    );

    expect(normalized.path, '/jellyfin');
  });

  test('should reject public HTTP when an insecure URL is submitted', () {
    expect(
      () => ServerUrlPolicy.normalize(
        'http://example.test',
        allowPrivateHttp: true,
      ),
      throwsA(isA<PublicHttpFailure>()),
    );
  });

  test(
    'should require confirmation for private HTTP when confirmation is absent',
    () {
      expect(
        () => ServerUrlPolicy.normalize('http://192.168.1.20:8096'),
        throwsA(isA<PrivateHttpConfirmationRequiredFailure>()),
      );
    },
  );

  test('should allow confirmed private HTTP when the host is on the LAN', () {
    final normalized = ServerUrlPolicy.normalize(
      'http://192.168.1.20:8096',
      allowPrivateHttp: true,
    );

    expect(normalized.scheme, 'http');
    expect(normalized.host, '192.168.1.20');
  });

  test('should classify only supported local HTTP hosts as private', () {
    const allowed = <String>[
      'localhost',
      'media.local',
      '127.0.0.1',
      '127.255.255.254',
      '10.0.0.2',
      '172.16.0.2',
      '172.31.255.254',
      '192.168.1.20',
      '169.254.10.5',
      '::1',
      'fc00::2',
      'fd12::2',
      'fe80::2',
    ];
    const rejected = <String>[
      'printer',
      'example.localhost',
      '172.15.0.2',
      '172.32.0.2',
      '192.167.1.20',
      '169.253.10.5',
      '8.8.8.8',
      '300.1.1.1',
    ];

    for (final host in allowed) {
      final candidate = host.contains(':') ? 'http://[$host]' : 'http://$host';
      expect(
        () => ServerUrlPolicy.normalize(candidate, allowPrivateHttp: true),
        returnsNormally,
        reason: host,
      );
    }
    for (final host in rejected) {
      expect(
        () => ServerUrlPolicy.normalize('http://$host', allowPrivateHttp: true),
        throwsA(isA<PublicHttpFailure>()),
        reason: host,
      );
    }
    expect(
      () =>
          ServerUrlPolicy.normalize('http://[fcgg::1]', allowPrivateHttp: true),
      throwsA(isA<InvalidServerUrlFailure>()),
    );
  });
}
