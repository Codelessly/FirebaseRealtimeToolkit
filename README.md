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
- **Flutter apps** - RTDB realtime streaming with user authentication
- **Dart CLI tools** - Admin scripts with service account access
- **Backend services** - Server-side Dart applications with Firestore access
- **Reducing bundle size** - When full Firebase SDK is overkill

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

> **⚠️ SECURITY WARNING - SERVER-SIDE ONLY**
>
> The `FirestoreListenClient` with `ServiceAccountTokenProvider` is designed for **server-side applications only** (backend services, CLI tools, CI/CD pipelines).
>
> **NEVER use service accounts in client applications** (Flutter mobile/web/desktop apps). Service accounts contain private keys that grant admin-level access to your entire Firebase project. If embedded in a client app, anyone can extract the credentials and:
> - Read/write/delete ALL data in your project
> - Impersonate any user
> - Rack up unlimited Firebase bills
> - Compromise your entire infrastructure
>
> **For client apps:** Use Firebase RTDB with user authentication tokens instead (see [Authenticated RTDB Access](#authenticated-rtdb-access)).

```dart
import 'package:firebase_realtime_toolkit/firebase_realtime_toolkit.dart';

// ⚠️ SERVER-SIDE ONLY - DO NOT use in Flutter apps
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

## Security Best Practices

### ⚠️ Service Account Security

| Feature | Safe for Client Apps? | Safe for Server Apps? |
|---------|----------------------|----------------------|
| **RTDB with user auth token** | ✅ YES | ✅ YES |
| **Generic SSE with user token** | ✅ YES | ✅ YES |
| **Firestore with service account** | ❌ **NEVER** | ✅ YES |

**Why service accounts are dangerous in client apps:**
- Service accounts contain private keys with admin access
- Anyone can decompile/extract credentials from your app
- Compromised credentials = complete project access
- Cannot be revoked without replacing everywhere

**Safe Alternatives for Client Apps:**

```dart
// ✅ SAFE: RTDB with Firebase Auth token
final client = RtdbSseClient(baseUri);
final stream = client.listen(
  '/users/$userId/data',
  authToken: firebaseUserIdToken, // From Firebase Auth SDK
);

// ✅ SAFE: Custom SSE endpoint with user authentication
final client = SseClient();
final stream = client.listen(
  Uri.parse('https://your-backend.com/stream'),
  headers: {'Authorization': 'Bearer $userToken'},
);
```

**Server-Side Only:**

```dart
// ✅ SAFE: Server-side Dart application
final tokenProvider = ServiceAccountTokenProvider(
  '/path/to/service-account.json',
);
final client = FirestoreListenClient(
  projectId: 'your-project-id',
  tokenProvider: tokenProvider,
);
```

## Platform Support

| Platform | RTDB SSE | Generic SSE | Firestore Listen |
|----------|----------|-------------|------------------|
| Dart VM (CLI) | ✅ | ✅ | ✅ (server-side only) |
| Flutter Android | ✅ | ✅ | ❌ (service account risk) |
| Flutter iOS | ✅ | ✅ | ❌ (service account risk) |
| Flutter macOS | ✅ | ✅ | ❌ (service account risk) |
| Flutter Windows | ✅ | ✅ | ❌ (service account risk) |
| Flutter Linux | ✅ | ✅ | ❌ (service account risk) |
| Flutter Web | ✅ | ✅* | ❌ (not supported) |

\* Web SSE uses browser's `EventSource` API and cannot use custom headers.
\*\* Firestore gRPC requires service accounts, which should NEVER be embedded in client applications.

## CLI Tools

The package includes command-line tools for testing and admin tasks.

### rtdb_sse

Test RTDB streaming with user authentication:

```bash
dart run firebase_realtime_toolkit:rtdb_sse \
  --base https://project-id-default-rtdb.firebaseio.com/ \
  --path /playground/status \
  --auth YOUR_AUTH_TOKEN \
  --duration 60
```

### firestore_listen

**Admin tool - requires service account (server-side only):**

```bash
dart run firebase_realtime_toolkit:firestore_listen \
  --service-account /path/to/service-account.json \
  --project my-project-id \
  --document collection/docId \
  --duration 30
```

### firestore_write

**Admin tool - requires service account (server-side only):**

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
| Client-Side Firestore | ❌ (security risk) | ✅ (secure) |
| Offline Support | ❌ | ✅ |
| Local Caching | ❌ | ✅ |
| Transactions | ❌ | ✅ |
| Complex Queries | ❌ | ✅ |
| Multi-path Listeners | ❌ | ✅ |
| Auto-reconnect | Partial | ✅ |
| Web Support | RTDB only | ✅ |

**Use this toolkit when:**
- You only need RTDB realtime streaming in client apps
- Bundle size is critical
- Building server-side Dart applications with Firestore
- Building CLI tools for Firebase admin tasks
- Want to avoid Firebase SDK initialization overhead

**Use official Firebase SDK when:**
- You need Firestore in client applications
- You need offline support
- You need complex queries
- You need transactions
- You need the full Firebase feature set

## Documentation

- [Architecture Guide](docs/ARCHITECTURE.md) - Detailed technical architecture
- [Usage Example](docs/EXAMPLE.md) - Real-world Storyboard case study with REST vs SSE comparison
- [Firebase RTDB REST API](https://firebase.google.com/docs/database/rest/retrieve-data#section-rest-streaming)
- [Firestore gRPC API](https://cloud.google.com/firestore/docs/reference/rpc/google.firestore.v1)

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

Developed by [Codelessly](https://codelessly.com)
