import 'dart:convert';

class SseEvent {
  final String event;
  final dynamic data;
  final String rawData;

  SseEvent({
    required this.event,
    required this.data,
    required this.rawData,
  });

  @override
  String toString() => 'SseEvent(event: $event, data: $data)';
}

SseEvent parseSseEvent(String event, String rawData) {
  dynamic parsed;
  try {
    parsed = json.decode(rawData);
  } catch (_) {
    parsed = rawData;
  }

  return SseEvent(event: event, data: parsed, rawData: rawData);
}
