import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'sse_client_base.dart';

class SseClient {
  final HttpClient _client;

  SseClient({HttpClient? httpClient}) : _client = httpClient ?? HttpClient();

  Stream<SseEvent> listen(
    Uri uri, {
    Map<String, String>? headers,
  }) {
    final controller = StreamController<SseEvent>();

    () async {
      final request = await _client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      request.headers.set(HttpHeaders.connectionHeader, 'keep-alive');
      headers?.forEach(request.headers.set);

      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        final body = await response.transform(utf8.decoder).join();
        controller.addError(
          HttpException(
              'SSE failed: ${response.statusCode} ${response.reasonPhrase}. $body'),
        );
        await controller.close();
        return;
      }

      final buffer = StringBuffer();
      await for (final chunk in response.transform(utf8.decoder)) {
        buffer.write(chunk);

        String current = buffer.toString();
        int boundaryIndex = _findEventBoundary(current);
        while (boundaryIndex != -1) {
          final rawEvent = current.substring(0, boundaryIndex);
          _handleEventBlock(rawEvent, controller);
          current = current
              .substring(boundaryIndex)
              .replaceFirst(RegExp(r'^\r?\n\r?\n'), '');
          boundaryIndex = _findEventBoundary(current);
        }

        buffer
          ..clear()
          ..write(current);
      }
    }();

    controller.onCancel = () async {
      _client.close(force: true);
    };

    return controller.stream;
  }

  int _findEventBoundary(String buffer) {
    final index = buffer.indexOf('\n\n');
    if (index != -1) return index + 2;
    final altIndex = buffer.indexOf('\r\n\r\n');
    if (altIndex != -1) return altIndex + 4;
    return -1;
  }

  void _handleEventBlock(
      String rawEvent, StreamController<SseEvent> controller) {
    String? event;
    final dataLines = <String>[];

    for (final line in const LineSplitter().convert(rawEvent)) {
      if (line.startsWith('event:')) {
        event = line.substring('event:'.length).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring('data:'.length).trim());
      }
    }

    if (event == null || dataLines.isEmpty) {
      return;
    }

    final rawData = dataLines.join('\n');
    controller.add(parseSseEvent(event, rawData));
  }
}
