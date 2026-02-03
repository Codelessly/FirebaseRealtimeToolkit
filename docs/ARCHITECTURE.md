# Firebase Realtime Toolkit - Technical Architecture

**Last Updated:** February 3, 2026
**Version:** 1.0.0

## Overview

Firebase Realtime Toolkit is a lightweight Dart library that provides realtime streaming clients for Firebase Realtime Database (RTDB) and Firestore without requiring the full Firebase SDK. This enables Flutter/Dart applications to receive real-time data updates with minimal dependencies and reduced bundle size.

### Key Value Proposition

| Approach | Dependencies | Bundle Impact | Use Case |
|----------|--------------|---------------|----------|
| **Full Firebase SDK** | Firebase Core + RTDB/Firestore packages | Large (~2-5MB) | Full Firebase features needed |
| **Firebase Realtime Toolkit** | http, grpc, protobuf, googleapis_auth | Minimal (~500KB) | Realtime updates only |

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    FIREBASE REALTIME TOOLKIT                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                         PUBLIC API LAYER                              │  │
│  │                                                                       │  │
│  │   firebase_realtime_toolkit.dart (exports)                           │  │
│  │     ├── RtdbSseClient      (Firebase RTDB streaming)                 │  │
│  │     ├── SseClient          (Generic SSE streaming)                   │  │
│  │     └── FirestoreListenClient (Firestore document listening)         │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌─────────────────────────┐    ┌────────────────────────────────────────┐ │
│  │    SSE Layer            │    │         gRPC Layer                     │ │
│  │                         │    │                                        │ │
│  │  ┌───────────────────┐  │    │  ┌─────────────────────────────────┐  │ │
│  │  │  SseClient        │  │    │  │  FirestoreListenClient          │  │ │
│  │  │  (Generic SSE)    │  │    │  │  (Document Listener)            │  │ │
│  │  └───────────────────┘  │    │  └─────────────────────────────────┘  │ │
│  │           │             │    │              │                        │ │
│  │  ┌────────┴────────┐    │    │     ┌────────┴────────┐               │ │
│  │  │  Platform       │    │    │     │ Auth Provider   │               │ │
│  │  │  Conditional    │    │    │     │ Interface       │               │ │
│  │  │  Import         │    │    │     └─────────────────┘               │ │
│  │  └────────┬────────┘    │    │              │                        │ │
│  │     ┌─────┴─────┐       │    │     ┌────────┴────────┐               │ │
│  │     │           │       │    │     │ Service Account │               │ │
│  │     ▼           ▼       │    │     │ Token Provider  │               │ │
│  │  IO Client   Web Client │    │     └─────────────────┘               │ │
│  │  (HttpClient) (EventSource) │                                        │ │
│  └─────────────────────────┘    └────────────────────────────────────────┘ │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                      RTDB SSE Client                                  │  │
│  │                                                                       │  │
│  │   RtdbSseClient wraps SseClient with Firebase-specific:              │  │
│  │     • URL building (/path.json format)                               │  │
│  │     • Auth token query parameter handling                            │  │
│  │     • Event type mapping (put, patch, keep-alive, etc.)              │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                   FIRESTORE PROTO LAYER                               │  │
│  │                                                                       │  │
│  │   Generated protobuf classes for Firestore gRPC API:                 │  │
│  │     • google/firestore/v1/firestore.pb.dart                          │  │
│  │     • google/firestore/v1/document.pb.dart                           │  │
│  │     • google/firestore/v1/write.pb.dart                              │  │
│  │     • Supporting Google API protobuf definitions                      │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. SSE Client Layer (`/lib/src/sse/`)

The SSE (Server-Sent Events) layer provides a generic streaming client that works across platforms.

#### File Structure

```
lib/src/sse/
├── sse_client.dart          # Conditional export (IO vs Web)
├── sse_client_base.dart     # Shared types and parsing
├── sse_client_io.dart       # Dart VM/Flutter implementation
└── sse_client_web.dart      # Browser implementation
```

#### SseEvent Model

```dart
class SseEvent {
  final String event;      // Event type (e.g., "put", "patch", "message")
  final dynamic data;      // Parsed JSON data (or raw string if not JSON)
  final String rawData;    // Original unparsed data
}
```

#### Platform-Specific Implementations

**IO Implementation (Dart VM, Flutter mobile/desktop):**
- Uses `HttpClient` for HTTP streaming
- Manual SSE protocol parsing (event/data line format)
- Handles chunked transfer encoding
- Sets proper headers: `Accept: text/event-stream`, `Cache-Control: no-cache`

**Web Implementation (Flutter Web):**
- Uses browser's native `EventSource` API
- Limited to standard event types (no custom headers)
- Automatic reconnection handled by browser

#### Usage Pattern

```dart
final client = SseClient();
final stream = client.listen(
  Uri.parse('https://example.com/events'),
  headers: {'Authorization': 'Bearer token'}, // IO only
);

stream.listen((event) {
  print('Event: ${event.event}, Data: ${event.data}');
});
```

### 2. RTDB SSE Client Layer (`/lib/src/rtdb/`)

Firebase Realtime Database-specific wrapper around the generic SSE client.

#### File Structure

```
lib/src/rtdb/
├── rtdb_sse_client.dart          # Conditional export
├── rtdb_sse_client_base.dart     # URI building, event types
├── rtdb_sse_client_io.dart       # IO implementation
└── rtdb_sse_client_web.dart      # Web implementation
```

#### RtdbSseEvent Model

```dart
class RtdbSseEvent {
  final String event;      // Firebase event type
  final dynamic data;      // Parsed data (usually {"path": ..., "data": ...})
  final String rawData;    // Raw JSON string
}
```

#### Firebase RTDB Event Types

| Event | Description |
|-------|-------------|
| `put` | Initial data or data set at path |
| `patch` | Partial update at path |
| `keep-alive` | Connection heartbeat (data is `null`) |
| `auth_revoked` | Authentication token expired |
| `cancel` | Permission denied or listener cancelled |

#### URL Building

```dart
Uri buildRtdbUri(
  Uri baseUri,     // e.g., https://project-id.firebaseio.com/
  String path,     // e.g., /users/123
  {
    String? authToken,           // Added as ?auth=TOKEN
    Map<String, String>? queryParameters,
  }
);

// Result: https://project-id.firebaseio.com/users/123.json?auth=TOKEN
```

#### Usage Pattern

```dart
final client = RtdbSseClient(
  Uri.parse('https://project-id-default-rtdb.firebaseio.com/'),
);

final subscription = client.listen(
  '/path/to/data',
  authToken: 'optional-auth-token',
).listen((event) {
  switch (event.event) {
    case 'put':
      final path = event.data['path'];
      final data = event.data['data'];
      // Handle full data update
      break;
    case 'patch':
      // Handle partial update
      break;
    case 'keep-alive':
      // Connection is alive
      break;
  }
});

// Cleanup
await subscription.cancel();
```

### 3. Firestore Listen Client (`/lib/src/firestore/`)

Firestore document listener using the native gRPC Listen API.

#### File Structure

```
lib/src/firestore/
└── firestore_listen_client.dart   # Main client implementation

lib/src/firestore_proto/          # Generated protobuf classes
├── google/firestore/v1/
│   ├── firestore.pb.dart         # Main service
│   ├── firestore.pbgrpc.dart     # gRPC stubs
│   ├── document.pb.dart          # Document model
│   ├── query.pb.dart             # Query definitions
│   └── write.pb.dart             # Write operations
├── google/api/                    # API annotations
├── google/protobuf/               # Common protobuf types
├── google/rpc/                    # Status codes
└── google/type/                   # Common types (LatLng, etc.)
```

#### Authentication

```dart
// Abstract interface for token provision
abstract class AccessTokenProvider {
  Future<AccessToken> getAccessToken();
}

// Service account implementation
class ServiceAccountTokenProvider implements AccessTokenProvider {
  final String serviceAccountJsonPath;
  final List<String> scopes;

  @override
  Future<AccessToken> getAccessToken() async {
    // Read service account JSON
    // Use googleapis_auth to get token
    return token;
  }
}
```

#### Client Configuration

```dart
class FirestoreListenClient {
  final String projectId;          // GCP project ID
  final String databaseId;         // Usually '(default)'
  final AccessTokenProvider tokenProvider;
  final ClientChannel _channel;    // gRPC channel
}
```

#### Usage Pattern

```dart
final tokenProvider = ServiceAccountTokenProvider(
  '/path/to/service-account.json',
);

final client = FirestoreListenClient(
  projectId: 'my-project-id',
  tokenProvider: tokenProvider,
);

final subscription = client.listenDocument('collection/docId').listen((response) {
  // response is ListenResponse protobuf
  if (response.hasDocumentChange()) {
    final doc = response.documentChange.document;
    final fields = doc.fields;  // Map<String, Value>
  }
});

// Cleanup
await subscription.cancel();
await client.close();
```

## Data Flow Diagrams

### RTDB SSE Data Flow

```
┌────────────┐     HTTP GET      ┌─────────────────────────┐
│  Client    │ ----------------> │  Firebase RTDB          │
│            │   Accept: text/   │  REST API               │
│            │   event-stream    │                         │
└────────────┘                   └───────────┬─────────────┘
      │                                      │
      │        SSE Stream                    │
      │  <---------------------------------- │
      │                                      │
      ▼                                      │
┌────────────┐                               │
│  Parse     │     event: put               │
│  SSE       │     data: {"path":"/",       │
│  Events    │            "data":{...}}     │
└────────────┘                               │
      │                                      │
      ▼                                      │
┌────────────┐                               │
│  Emit      │                               │
│  RtdbSse   │                               │
│  Event     │                               │
└────────────┘
```

### Firestore gRPC Data Flow

```
┌────────────┐    ListenRequest     ┌─────────────────────────┐
│  Client    │ ------------------->  │  Firestore gRPC API     │
│            │   (addTarget)        │  firestore.googleapis.com│
└────────────┘                       └───────────┬─────────────┘
      │                                          │
      │      Bidirectional Stream                │
      │  <-------------------------------------> │
      │                                          │
      ▼                                          │
┌────────────┐     ListenResponse               │
│  Handle    │  • targetChange (CURRENT)        │
│  Response  │  • documentChange (doc data)     │
│  Types     │  • documentDelete                │
│            │  • filter                        │
└────────────┘
```

## Platform Support Matrix

| Platform | RTDB SSE | Generic SSE | Firestore Listen |
|----------|----------|-------------|------------------|
| Dart VM (CLI) | ✅ | ✅ | ✅ |
| Flutter Android | ✅ | ✅ | ✅ |
| Flutter iOS | ✅ | ✅ | ✅ |
| Flutter macOS | ✅ | ✅ | ✅ |
| Flutter Windows | ✅ | ✅ | ✅ |
| Flutter Linux | ✅ | ✅ | ✅ |
| Flutter Web | ✅ | ✅ (limited)* | ❌** |

*Web SSE: Cannot use custom headers due to EventSource API limitations.
**Firestore gRPC: Not available in browsers; use Firebase JS SDK instead.

## Dependencies

```yaml
dependencies:
  grpc: ^5.1.0              # gRPC client for Firestore
  protobuf: ^6.0.0          # Protobuf runtime
  fixnum: ^1.1.1            # Fixed-width integers (protobuf)
  googleapis_auth: ^2.0.0   # Google OAuth/service account auth
  http: ^1.2.2              # HTTP client (used for SSE on IO)
```

## Command-Line Tools

The package includes CLI tools for testing and debugging:

### rtdb_sse

Stream data from Firebase RTDB:

```bash
dart run firebase_realtime_toolkit:rtdb_sse \
  --base https://project-id-default-rtdb.firebaseio.com/ \
  --path /playground/status \
  --auth YOUR_AUTH_TOKEN \
  --duration 60
```

### firestore_listen

Listen to Firestore document changes:

```bash
dart run firebase_realtime_toolkit:firestore_listen \
  --service-account /path/to/service-account.json \
  --project my-project-id \
  --document collection/docId \
  --duration 30
```

### firestore_write

Write to Firestore (for testing):

```bash
dart run firebase_realtime_toolkit:firestore_write \
  --service-account /path/to/service-account.json \
  --project my-project-id \
  --document collection/docId \
  --field status \
  --value "updated"
```

## Error Handling

### SSE Errors

```dart
client.listen(uri).listen(
  (event) => handleEvent(event),
  onError: (error) {
    if (error is HttpException) {
      // HTTP-level error (4xx, 5xx status)
    } else if (error is StateError) {
      // SSE protocol error
    }
  },
);
```

### Firestore gRPC Errors

```dart
client.listenDocument(path).listen(
  (response) => handleResponse(response),
  onError: (error) {
    if (error is GrpcError) {
      switch (error.code) {
        case StatusCode.unauthenticated:
          // Token expired or invalid
          break;
        case StatusCode.permissionDenied:
          // No access to document
          break;
        case StatusCode.notFound:
          // Document doesn't exist
          break;
      }
    }
  },
);
```

## Security Considerations

### RTDB Authentication

- Pass auth tokens via `authToken` parameter (added as `?auth=` query param)
- Tokens appear in URL - use HTTPS and avoid logging URLs
- Firebase ID tokens can be obtained from Firebase Auth SDK

### Firestore Authentication

- Uses Google Cloud service account credentials
- Service account JSON must be kept secure (never commit to repos)
- Consider using environment variables or secure vaults in production

## Performance Characteristics

| Operation | Latency | Notes |
|-----------|---------|-------|
| RTDB SSE connect | ~100-300ms | Initial HTTP handshake |
| RTDB SSE update | ~50-100ms | After connection established |
| Firestore gRPC connect | ~200-500ms | TLS + gRPC handshake |
| Firestore update | ~50-150ms | After stream established |

## Comparison with Official SDKs

| Feature | Firebase Realtime Toolkit | Official Firebase SDK |
|---------|---------------------------|----------------------|
| Bundle Size | ~500KB | ~2-5MB |
| Offline Support | ❌ | ✅ |
| Local Caching | ❌ | ✅ |
| Transactions | ❌ (write only) | ✅ |
| Queries | ❌ | ✅ |
| Multi-path Listeners | ❌ | ✅ |
| Auto-reconnect | Partial | ✅ |
| Web Support | ✅ (RTDB only) | ✅ |

## Future Enhancements

### Planned Features

- [ ] Auto-reconnection with exponential backoff
- [ ] Query support for RTDB
- [ ] Multi-document listeners for Firestore
- [ ] Connection state callbacks
- [ ] Configurable retry policies

### Under Consideration

- [ ] Firestore query listeners (requires complex protobuf handling)
- [ ] RTDB transaction support via REST API
- [ ] Anonymous/custom auth token generation

## Real-World Usage Example

For a detailed case study showing how the Firebase Realtime Toolkit compares to traditional REST polling approaches, see [EXAMPLE.md](EXAMPLE.md).

The case study analyzes the Flutter Rebound storyboard's cloud sync implementation and demonstrates:
- Architecture comparison (REST polling vs SSE streaming)
- Performance metrics and benefits
- Code examples for migration
- Hybrid architecture recommendations

---

## Related Documentation

- [Firebase RTDB REST API](https://firebase.google.com/docs/database/rest/retrieve-data#section-rest-streaming)
- [Firestore gRPC API Reference](https://cloud.google.com/firestore/docs/reference/rpc/google.firestore.v1)
- [Server-Sent Events Specification](https://html.spec.whatwg.org/multipage/server-sent-events.html)

---

## Change Log

| Date | Version | Changes |
|------|---------|---------|
| 2026-02-03 | 1.2.0 | Moved case study to separate EXAMPLE.md file |
| 2026-02-03 | 1.1.0 | Added real-world Storyboard Cloud Sync case study with REST vs SSE comparison |
| 2026-02-03 | 1.0.0 | Initial architecture documentation |
