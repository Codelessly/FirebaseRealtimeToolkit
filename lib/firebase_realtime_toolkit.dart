/// Lightweight realtime clients for Firebase RTDB and Firestore.
library firebase_realtime_toolkit;

// Auth - client-side authentication without service accounts
export 'src/auth/firebase_auth_client.dart';
export 'src/auth/id_token_provider.dart';

// Realtime clients
export 'src/rtdb/rtdb_sse_client.dart';
export 'src/sse/sse_client.dart';
export 'src/firestore/firestore_listen_client.dart';
