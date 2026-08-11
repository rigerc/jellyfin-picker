import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/core/config/environment_config.dart';

void main() {
  test(
    'should load custom runtime values when staging defines are supplied',
    () {
      const config = EnvironmentConfig.fromEnvironment();

      expect(config.environmentName, 'staging');
      expect(config.jellyfinServerUrl, 'https://example.test');
      expect(config.enableDiagnostics, isTrue);
    },
  );
}
