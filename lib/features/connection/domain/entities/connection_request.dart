/// Credentials and server address submitted for a connection attempt.
final class ConnectionRequest {
  const ConnectionRequest({
    required this.baseUrl,
    required this.username,
    required this.password,
    this.allowPrivateHttp = false,
  });

  final String baseUrl;
  final String username;
  final String password;
  final bool allowPrivateHttp;

  ConnectionRequest copyWith({bool? allowPrivateHttp}) {
    return ConnectionRequest(
      baseUrl: baseUrl,
      username: username,
      password: password,
      allowPrivateHttp: allowPrivateHttp ?? this.allowPrivateHttp,
    );
  }
}
