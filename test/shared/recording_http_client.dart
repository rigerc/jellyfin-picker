import 'dart:async';

import 'package:http/http.dart' as http;

typedef RequestHandler =
    Future<http.Response> Function(http.BaseRequest request);

final class RecordingHttpClient extends http.BaseClient {
  RecordingHttpClient(this.handler);

  final RequestHandler handler;
  final List<http.BaseRequest> requests = <http.BaseRequest>[];
  final List<String?> bodies = <String?>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    bodies.add(request is http.Request ? request.body : null);
    final response = await handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: request,
    );
  }
}
