# Firebase Realtime Toolkit

[![Pub Version](https://img.shields.io/pub/v/firebase_realtime_toolkit)](https://pub.dev/packages/firebase_realtime_toolkit)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Lightweight realtime streaming clients for **Firebase Realtime Database (RTDB)** and **Firestore** in Dart/Flutter, without the full Firebase SDK overhead.

## Why Use This?

| Approach | Bundle Size | Dependencies |
|----------|-------------|--------------|
| Full Firebase SDK | ~2-5MB | Firebase Core + Auth + RTDB/Firestore |
| **Firebase Realtime Toolkit** | **~500KB** | http, grpc, protobuf, googleapis_auth |

Perfect for:
- Lightweight Flutter apps that only need realtime data streaming
- Dart CLI tools and servers that need Firebase realtime updates
- Reducing app bundle size when full Firebase features aren't needed
- Server-side Dart applications

## Features

- **RTDB Realtime Streaming** - Subscribe to Firebase Realtime Database paths via REST SSE
- **Firestore Document Listening** - Subscribe to Firestore document changes via gRPC
- **Generic SSE Client** - Use with any Server-Sent Events endpoint
- **Cross-Platform** - Works on Dart VM, Flutter mobile, desktop, and web (RTDB only)
- **Minimal Dependencies** - No Firebase SDK required

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  firebase_realtime_toolkit: ^1.0.0
```

Or install via command line:

```bash
dart pub add firebase_realtime_toolkit
```

## Quick Start

### Firebase Realtime Database

```dart
import 'package:firebase_realtime_toolkit/firebase_realtime_toolkit.dart';

void main() async {
  final client = RtdbSseClient(
    Uri.parse('https://your-project-id-default-rtdb.firebaseio.com/'),
  );

  final subscription = client.listen('/path/to/data').listen((event) {
    print('Event: ${event.event}');
    print('Data: ${event.data}');
  });

  // When done
  await subscription.cancel();
}
```

### Firestore Document Listener

```dart
import 'package:firebase_realtime_toolkit/firebase_realtime_toolkit.dart';

void main() async {
  final tokenProvider = ServiceAccountTokenProvider(
    '/path/to/service-account.json',
  );

  final client = FirestoreListenClient(
    projectId: 'your-project-id',
    tokenProvider: tokenProvider,
  );

  final subscription = client.listenDocument('collection/docId').listen((response) {
    if (response.hasDocumentChange()) {
      print('Document changed: ${response.documentChange.document.fields}');
    }
  });

  // When done
  await subscription.cancel();
  await client.close();
}
```

### Generic SSE Client

```dart
import 'package:firebase_realtime_toolkit/firebase_realtime_toolkit.dart';

void main() async {
  final client = SseClient();

  final subscription = client.listen(
    Uri.parse('https://example.com/events'),
    headers: {'Authorization': 'Bearer token'}, // IO platforms only
  ).listen((event) {
    print('${event.event}: ${event.data}');
  });

  await subscription.cancel();
}
```

## API Reference

### RtdbSseClient

Client for Firebase Realtime Database streaming via REST SSE.

```dart
class RtdbSseClient {
  RtdbSseClient(Uri baseUri);

  Stream<RtdbSseEvent> listen(
    String path, {
    String? authToken,
    Map<String, String>? queryParameters,
  });
}
```

**Parameters:**
- `baseUri` - Firebase RTDB URL (e.g., `https://project-id.firebaseio.com/`)
- `path` - Database path to listen to (e.g., `/users/123`)
- `authToken` - Optional Firebase Auth token for authenticated requests
- `queryParameters` - Optional query parameters (orderBy, limitToFirst, etc.)

**Event Types:**

| Event | Description |
|-------|-------------|
| `put` | Initial data load or data set at path |
| `patch` | Partial update to data |
| `keep-alive` | Heartbeat (data is `null`) |
| `auth_revoked` | Authentication token expired |
| `cancel` | Listener cancelled or permission denied |

### RtdbSseEvent

```dart
class RtdbSseEvent {
  final String event;     // Event type
  final dynamic data;     // Parsed JSON data
  final String rawData;   // Raw data string
}
```

### FirestoreListenClient

Client for Firestore document listening via gRPC.

```dart
class FirestoreListenClient {
  FirestoreListenClient({
    required String projectId,
    String databaseId = '(default)',
    required AccessTokenProvider tokenProvider,
    ClientChannel? channel,
  });

  Stream<ListenResponse> listenDocument(
    String documentPath, {
    int targetId = 1,
  });

  Future<void> close();
}
```

**Parameters:**
- `projectId` - Google Cloud project ID
- `databaseId` - Firestore database ID (usually `(default)`)
- `tokenProvider` - Token provider for authentication
- `documentPath` - Document path (e.g., `collection/docId`)

### AccessTokenProvider

Abstract interface for providing authentication tokens.

```dart
abstract class AccessTokenProvider {
  Future<AccessToken> getAccessToken();
}

// Built-in implementation for service accounts
class ServiceAccountTokenProvider implements AccessTokenProvider {
  ServiceAccountTokenProvider(
    String serviceAccountJsonPath, {
    List<String> scopes = FirestoreClient.oauthScopes,
  });
}
```

### SseClient

Generic SSE client for any Server-Sent Events endpoint.

```dart
class SseClient {
  Stream<SseEvent> listen(
    Uri uri, {
    Map<String, String>? headers, // IO platforms only
  });
}
```

### SseEvent

```dart
class SseEvent {
  final String event;     // Event type
  final dynamic data;     // Parsed JSON data (or raw string)
  final String rawData;   // Raw data string
}
```

## Platform Support

| Platform | RTDB SSE | Generic SSE | Firestore Listen |
|----------|----------|-------------|------------------|
| Dart VM (CLI) | ✅ | ✅ | ✅ |
| Flutter Android | ✅ | ✅ | ✅ |
| Flutter iOS | ✅ | ✅ | ✅ |
| Flutter macOS | ✅ | ✅ | ✅ |
| Flutter Windows | ✅ | ✅ | ✅ |
| Flutter Linux | ✅ | ✅ | ✅ |
| Flutter Web | ✅ | ✅* | ❌** |

\* Web SSE uses browser's `EventSource` API and cannot use custom headers.
\** Firestore gRPC is not supported in browsers; use Firebase JS SDK instead.

## CLI Tools

The package includes command-line tools for testing:

### rtdb_sse

```bash
dart run firebase_realtime_toolkit:rtdb_sse \
  --base https://project-id-default-rtdb.firebaseio.com/ \
  --path /playground/status \
  --auth YOUR_AUTH_TOKEN \
  --duration 60
```

### firestore_listen

```bash
dart run firebase_realtime_toolkit:firestore_listen \
  --service-account /path/to/service-account.json \
  --project my-project-id \
  --document collection/docId \
  --duration 30
```

### firestore_write

```bash
dart run firebase_realtime_toolkit:firestore_write \
  --service-account /path/to/service-account.json \
  --project my-project-id \
  --document collection/docId \
  --field status \
  --value "updated"
```

## Advanced Usage

### Authenticated RTDB Access

```dart
// With Firebase Auth token
final client = RtdbSseClient(baseUri);
final stream = client.listen(
  '/private/data',
  authToken: userIdToken, // From Firebase Auth
);
```

### Custom gRPC Channel (Firestore)

```dart
final channel = ClientChannel(
  'firestore.googleapis.com',
  port: 443,
  options: ChannelOptions(
    credentials: ChannelCredentials.secure(),
    connectionTimeout: Duration(seconds: 30),
  ),
);

final client = FirestoreListenClient(
  projectId: 'my-project',
  tokenProvider: tokenProvider,
  channel: channel,
);
```

### Error Handling

```dart
client.listen('/path').listen(
  (event) {
    // Handle event
  },
  onError: (error) {
    if (error is HttpException) {
      print('HTTP error: ${error.message}');
    } else if (error is GrpcError) {
      print('gRPC error: ${error.code} - ${error.message}');
    }
  },
  onDone: () {
    print('Stream closed');
  },
);
```

## Comparison with Official Firebase SDK

| Feature | Firebase Realtime Toolkit | Official Firebase SDK |
|---------|---------------------------|----------------------|
| Bundle Size | ~500KB | ~2-5MB |
| Realtime Streaming | ✅ | ✅ |
| Offline Support | ❌ | ✅ |
| Local Caching | ❌ | ✅ |
| Transactions | ❌ | ✅ |
| Complex Queries | ❌ | ✅ |
| Multi-path Listeners | ❌ | ✅ |
| Auto-reconnect | Partial | ✅ |
| Web Support | RTDB only | ✅ |

**Use this toolkit when:**
- You only need realtime data streaming
- Bundle size is critical
- Building server-side Dart applications
- Want to avoid Firebase SDK initialization overhead

**Use official Firebase SDK when:**
- You need offline support
- You need complex queries
- You need transactions
- You need the full Firebase feature set

## Documentation

- [Architecture Guide](docs/ARCHITECTURE.md) - Detailed technical architecture
- [Firebase RTDB REST API](https://firebase.google.com/docs/database/rest/retrieve-data#section-rest-streaming)
- [Firestore gRPC API](https://cloud.google.com/firestore/docs/reference/rpc/google.firestore.v1)

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

Developed by [Codelessly](https://codelessly.com)
