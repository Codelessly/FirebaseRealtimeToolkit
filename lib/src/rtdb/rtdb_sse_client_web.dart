// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:html';

import 'rtdb_sse_client_base.dart';

class RtdbSseClient {
  final Uri baseUri;

  RtdbSseClient(this.baseUri);

  Stream<RtdbSseEvent> listen(
    String path, {
    String? authToken,
    Map<String, String>? queryParameters,
  }) {
    final controller = StreamController<RtdbSseEvent>();
    final uri = buildRtdbUri(baseUri, path,
        authToken: authToken, queryParameters: queryParameters);

    final eventSource = EventSource(uri.toString());

    void handleEvent(String eventName, Event event) {
      if (event is! MessageEvent) return;
      final raw = event.data?.toString() ?? '';
      if (raw.isEmpty) return;
      controller.add(toRtdbEvent(eventName, raw));
    }

    const eventTypes = <String>[
      'put',
      'patch',
      'keep-alive',
      'auth_revoked',
      'cancel',
    ];

    for (final type in eventTypes) {
      eventSource.addEventListener(type, (event) => handleEvent(type, event));
    }

    eventSource.onError.listen((event) {
      if (!controller.isClosed) {
        controller.addError(StateError('RTDB SSE error: $event'));
      }
    });

    controller.onCancel = () {
      eventSource.close();
    };

    return controller.stream;
  }
}
