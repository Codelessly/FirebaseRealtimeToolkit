import 'dart:convert';

class RtdbSseEvent {
  final String event;
  final dynamic data;
  final String rawData;

  RtdbSseEvent({
    required this.event,
    required this.data,
    required this.rawData,
  });

  @override
  String toString() => 'RtdbSseEvent(event: $event, data: $data)';
}

Uri buildRtdbUri(
  Uri baseUri,
  String path, {
  String? authToken,
  Map<String, String>? queryParameters,
}) {
  final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
  final base = baseUri.toString().endsWith('/')
      ? baseUri.toString()
      : '${baseUri.toString()}/';
  final uri = Uri.parse('$base$normalizedPath.json');

  final params = <String, String>{...uri.queryParameters};
  if (authToken != null && authToken.isNotEmpty) {
    params['auth'] = authToken;
  }
  if (queryParameters != null) {
    params.addAll(queryParameters);
  }

  return uri.replace(queryParameters: params.isEmpty ? null : params);
}

RtdbSseEvent toRtdbEvent(String event, String rawData) {
  dynamic parsed;
  try {
    parsed = json.decode(rawData);
  } catch (_) {
    parsed = rawData;
  }

  return RtdbSseEvent(event: event, data: parsed, rawData: rawData);
}
