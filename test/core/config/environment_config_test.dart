import 'package:flutter_test/flutter_test.dart';
import 'package:jellyfin_picker/core/config/environment_config.dart';

void main() {
  test('should use safe development defaults when no defines are supplied', () {
    const config = EnvironmentConfig.fromEnvironment();

    expect(config.environmentName, 'development');
    expect(config.jellyfinServerUrl, isEmpty);
    expect(config.enableDiagnostics, isFalse);
  });
}
