import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/features/connection/domain/entities/connection_request.dart';

void main() {
  test(
    'should preserve credentials when private HTTP confirmation is enabled',
    () {
      const request = ConnectionRequest(
        baseUrl: 'http://192.168.1.20:8096',
        username: 'alice',
        password: 'password',
      );

      final confirmed = request.copyWith(allowPrivateHttp: true);

      expect(confirmed.baseUrl, request.baseUrl);
      expect(confirmed.username, request.username);
      expect(confirmed.password, request.password);
      expect(confirmed.allowPrivateHttp, isTrue);
    },
  );
}
