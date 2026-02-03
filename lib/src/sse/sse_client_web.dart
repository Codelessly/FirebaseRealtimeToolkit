// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:html';

import 'sse_client_base.dart';

class SseClient {
  Stream<SseEvent> listen(
    Uri uri, {
    Map<String, String>? headers,
  }) {
    final controller = StreamController<SseEvent>();

    if (headers != null && headers.isNotEmpty) {
      controller.addError(
        StateError('SseClient (web) does not support custom headers.'),
      );
      controller.close();
      return controller.stream;
    }

    final eventSource = EventSource(uri.toString());

    void handleEvent(String eventName, Event event) {
      if (event is! MessageEvent) return;
      final raw = event.data?.toString() ?? '';
      if (raw.isEmpty) return;
      controller.add(parseSseEvent(eventName, raw));
    }

    const eventTypes = <String>[
      'message',
      'status',
      'annotations',
      'keep-alive',
      'error',
    ];

    for (final type in eventTypes) {
      eventSource.addEventListener(type, (event) => handleEvent(type, event));
    }

    eventSource.onError.listen((event) {
      if (!controller.isClosed) {
        controller.addError(StateError('SSE error: $event'));
      }
    });

    controller.onCancel = () {
      eventSource.close();
    };

    return controller.stream;
  }
}
