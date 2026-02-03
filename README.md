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

### Firestore Document Listener (Client-Side with User Auth) ✨

Listen to Firestore documents **without service accounts** using Firebase Authentication:

```dart
import 'package:firebase_realtime_toolkit/firebase_realtime_toolkit.dart';

void main() async {
  // Sign in anonymously (or with email/password)
  final tokenProvider = await IdTokenProvider.signInAnonymously(
    apiKey: 'your-firebase-web-api-key', // From Firebase Console
    projectId: 'your-project-id',
  );

  final client = FirestoreListenClient(
    projectId: 'your-project-id',
    tokenProvider: tokenProvider,
  );

  // Listen to documents - no service account needed!
  final subscription = client.listenDocument('public/status').listen((response) {
    if (response.hasDocumentChange()) {
      print('Document changed: ${response.documentChange.document.fields}');
    }
  });

  // When done
  await subscription.cancel();
  await client.close();
  tokenProvider.close();
}
```

**Prerequisites:**
1. Enable Anonymous Authentication in Firebase Console
2. Configure Firestore Security Rules:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /public/{document=**} {
         allow read: if request.auth != null;
       }
     }
   }
   ```

### Firestore Document Listener (Server-Side with Service Account)

> **⚠️ SECURITY WARNING - SERVER-SIDE ONLY**
>
> The `ServiceAccountTokenProvider` is designed for **server-side applications only** (backend services, CLI tools, CI/CD pipelines).
>
> **NEVER use service accounts in client applications** (Flutter mobile/web/desktop apps). Service accounts contain private keys that grant admin-level access to your entire Firebase project.

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
```

### IdTokenProvider (Client-Side)

Provides Firebase ID tokens for client-side authentication using Firebase Auth REST API.

```dart
// Sign in anonymously
final provider = await IdTokenProvider.signInAnonymously(
  apiKey: 'your-firebase-web-api-key',
  projectId: 'your-project-id',
);

// Sign in with email/password
final provider = await IdTokenProvider.signInWithEmailPassword(
  apiKey: 'your-firebase-web-api-key',
  projectId: 'your-project-id',
  email: 'user@example.com',
  password: 'password123',
);

// Sign in with custom token (from admin SDK)
final provider = await IdTokenProvider.signInWithCustomToken(
  apiKey: 'your-firebase-web-api-key',
  projectId: 'your-project-id',
  customToken: customTokenFromServer,
);

// Restore from saved session
final provider = await IdTokenProvider.fromSavedTokens(
  apiKey: apiKey,
  projectId: projectId,
  idToken: savedIdToken,
  refreshToken: savedRefreshToken,
  userId: savedUserId,
);
```

**Features:**
- Automatic token refresh (tokens expire after 1 hour)
- Save/restore session state
- Works with Firestore security rules

### ServiceAccountTokenProvider (Server-Side)

For server-side applications with service account credentials.

```dart
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

### ⚠️ Authentication Security

| Feature | Safe for Client Apps? | Safe for Server Apps? |
|---------|----------------------|----------------------|
| **RTDB with user auth token** | ✅ YES | ✅ YES |
| **Generic SSE with user token** | ✅ YES | ✅ YES |
| **Firestore with IdTokenProvider** | ✅ YES | ✅ YES |
| **Firestore with service account** | ❌ **NEVER** | ✅ YES |

**Why service accounts are dangerous in client apps:**
- Service accounts contain private keys with admin access
- Anyone can decompile/extract credentials from your app
- Compromised credentials = complete project access
- Cannot be revoked without replacing everywhere

**Safe Alternatives for Client Apps:**

```dart
// ✅ SAFE: Firestore with IdTokenProvider (anonymous auth)
final tokenProvider = await IdTokenProvider.signInAnonymously(
  apiKey: 'your-firebase-web-api-key',
  projectId: 'your-project-id',
);
final client = FirestoreListenClient(
  projectId: 'your-project-id',
  tokenProvider: tokenProvider,
);
final stream = client.listenDocument('public/status');

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
| Dart VM (CLI) | ✅ | ✅ | ✅ |
| Flutter Android | ✅ | ✅ | ✅ (with IdTokenProvider) |
| Flutter iOS | ✅ | ✅ | ✅ (with IdTokenProvider) |
| Flutter macOS | ✅ | ✅ | ✅ (with IdTokenProvider) |
| Flutter Windows | ✅ | ✅ | ✅ (with IdTokenProvider) |
| Flutter Linux | ✅ | ✅ | ✅ (with IdTokenProvider) |
| Flutter Web | ✅ | ✅* | ❌ (gRPC not supported) |

\* Web SSE uses browser's `EventSource` API and cannot use custom headers.
\*\* Firestore on Web requires the official Firebase SDK due to gRPC limitations in browsers.

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

### firestore_listen_anonymous

**Client-side tool - uses Firebase Auth (no service account needed):**

```bash
dart run firebase_realtime_toolkit:firestore_listen_anonymous \
  --api-key YOUR_FIREBASE_WEB_API_KEY \
  --project my-project-id \
  --document public/status
```

Prerequisites:
1. Enable Anonymous Authentication in Firebase Console
2. Configure Firestore Security Rules to allow anonymous access

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
| Client-Side Firestore | ✅ (with IdTokenProvider) | ✅ |
| Offline Support | ❌ | ✅ |
| Local Caching | ❌ | ✅ |
| Transactions | ❌ | ✅ |
| Complex Queries | ❌ | ✅ |
| Multi-path Listeners | ❌ | ✅ |
| Auto-reconnect | Partial | ✅ |
| Web Support | RTDB only | ✅ |

**Use this toolkit when:**
- You need lightweight Firestore realtime listening with minimal bundle size
- You only need RTDB realtime streaming in client apps
- Bundle size is critical
- Building server-side Dart applications with Firestore
- Building CLI tools for Firebase admin tasks
- Want to avoid Firebase SDK initialization overhead

**Use official Firebase SDK when:**
- You need offline support
- You need complex queries
- You need transactions
- You need Firestore on web
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
