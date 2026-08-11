/// Runtime configuration loaded from `--dart-define` values.
final class EnvironmentConfig {
  const EnvironmentConfig({
    required this.environmentName,
    required this.jellyfinServerUrl,
    required this.enableDiagnostics,
  });

  /// Creates configuration from compile-time environment definitions.
  const EnvironmentConfig.fromEnvironment()
    : environmentName = const String.fromEnvironment(
        'APP_ENVIRONMENT',
        defaultValue: 'development',
      ),
      jellyfinServerUrl = const String.fromEnvironment('JELLYFIN_SERVER_URL'),
      enableDiagnostics = const bool.fromEnvironment(
        'ENABLE_DIAGNOSTICS',
        defaultValue: false,
      );

  final String environmentName;
  final String jellyfinServerUrl;
  final bool enableDiagnostics;
}
