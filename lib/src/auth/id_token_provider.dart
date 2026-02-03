import 'package:googleapis_auth/auth_io.dart' as auth;

import '../firestore/firestore_listen_client.dart';
import 'firebase_auth_client.dart';

/// Provides Firebase ID tokens for client-side authentication with Firestore.
///
/// This provider uses Firebase Auth REST API to authenticate users
/// without requiring service account credentials. It supports:
///
/// - Anonymous authentication
/// - Email/password authentication
/// - Custom token authentication (from admin SDK)
///
/// The provider automatically refreshes expired tokens.
///
/// ## Example: Anonymous Authentication
///
/// ```dart
/// final provider = await IdTokenProvider.signInAnonymously(
///   apiKey: 'your-firebase-web-api-key',
///   projectId: 'your-project-id',
/// );
///
/// final client = FirestoreListenClient(
///   projectId: 'your-project-id',
///   tokenProvider: provider,
/// );
///
/// // Listen to a document - no service account needed!
/// await for (final response in client.listenDocument('users/user123')) {
///   print('Document updated: ${response.documentChange}');
/// }
/// ```
///
/// ## Security Rules
///
/// Your Firestore security rules must allow access for the auth type used:
///
/// ```javascript
/// // Allow authenticated users (including anonymous)
/// match /public/{document=**} {
///   allow read: if request.auth != null;
/// }
///
/// // Allow only the document owner
/// match /users/{userId} {
///   allow read, write: if request.auth != null && request.auth.uid == userId;
/// }
/// ```
class IdTokenProvider implements AccessTokenProvider {
  IdTokenProvider._({
    required this.apiKey,
    required this.projectId,
    required String idToken,
    String? refreshToken,
    required int expiresInSeconds,
    required this.userId,
    FirebaseAuthClient? authClient,
  })  : _currentIdToken = idToken,
        _refreshToken = refreshToken,
        _tokenExpiresAt =
            DateTime.now().add(Duration(seconds: expiresInSeconds)),
        _authClient = authClient ?? FirebaseAuthClient(apiKey: apiKey);

  /// Firebase Web API Key.
  final String apiKey;

  /// Firebase project ID.
  final String projectId;

  /// The authenticated user's unique ID.
  final String userId;

  final FirebaseAuthClient _authClient;
  String _currentIdToken;
  String? _refreshToken;
  DateTime _tokenExpiresAt;

  /// Buffer time before expiration to trigger refresh (default 5 minutes).
  Duration refreshBuffer = const Duration(minutes: 5);

  /// Whether the current token is expired or will expire soon.
  bool get isTokenExpired =>
      DateTime.now().add(refreshBuffer).isAfter(_tokenExpiresAt);

  /// The current ID token (may be expired).
  String get currentIdToken => _currentIdToken;

  /// Sign in anonymously and create a new IdTokenProvider.
  ///
  /// This creates a new anonymous user with a unique UID.
  /// The user can be upgraded to a full account later.
  static Future<IdTokenProvider> signInAnonymously({
    required String apiKey,
    required String projectId,
    FirebaseAuthClient? authClient,
  }) async {
    final client = authClient ?? FirebaseAuthClient(apiKey: apiKey);

    try {
      final result = await client.signInAnonymously();

      return IdTokenProvider._(
        apiKey: apiKey,
        projectId: projectId,
        idToken: result.idToken,
        refreshToken: result.refreshToken,
        expiresInSeconds: result.expiresIn,
        userId: result.localId,
        authClient: client,
      );
    } catch (e) {
      client.close();
      rethrow;
    }
  }

  /// Sign in with email and password.
  ///
  /// The user must already exist in Firebase Auth.
  static Future<IdTokenProvider> signInWithEmailPassword({
    required String apiKey,
    required String projectId,
    required String email,
    required String password,
    FirebaseAuthClient? authClient,
  }) async {
    final client = authClient ?? FirebaseAuthClient(apiKey: apiKey);

    try {
      final result = await client.signInWithEmailPassword(
        email: email,
        password: password,
      );

      return IdTokenProvider._(
        apiKey: apiKey,
        projectId: projectId,
        idToken: result.idToken,
        refreshToken: result.refreshToken,
        expiresInSeconds: result.expiresIn,
        userId: result.localId,
        authClient: client,
      );
    } catch (e) {
      client.close();
      rethrow;
    }
  }

  /// Sign in with a custom token from the admin SDK.
  ///
  /// Use this when you have a server that generates custom tokens
  /// with specific claims for the user.
  static Future<IdTokenProvider> signInWithCustomToken({
    required String apiKey,
    required String projectId,
    required String customToken,
    FirebaseAuthClient? authClient,
  }) async {
    final client = authClient ?? FirebaseAuthClient(apiKey: apiKey);

    try {
      final result = await client.signInWithCustomToken(customToken);

      return IdTokenProvider._(
        apiKey: apiKey,
        projectId: projectId,
        idToken: result.idToken,
        refreshToken: result.refreshToken,
        expiresInSeconds: result.expiresIn,
        userId: result.localId,
        authClient: client,
      );
    } catch (e) {
      client.close();
      rethrow;
    }
  }

  /// Create a provider from existing tokens.
  ///
  /// Use this when you have saved tokens from a previous session.
  /// The tokens will be refreshed automatically if expired (requires refreshToken).
  static Future<IdTokenProvider> fromSavedTokens({
    required String apiKey,
    required String projectId,
    required String idToken,
    String? refreshToken,
    required String userId,
    DateTime? expiresAt,
    FirebaseAuthClient? authClient,
  }) async {
    final client = authClient ?? FirebaseAuthClient(apiKey: apiKey);

    // If we don't know the expiration, assume it might be expired
    final expiresInSeconds = expiresAt != null
        ? expiresAt.difference(DateTime.now()).inSeconds
        : 0; // Will trigger refresh on first use

    return IdTokenProvider._(
      apiKey: apiKey,
      projectId: projectId,
      idToken: idToken,
      refreshToken: refreshToken,
      expiresInSeconds: expiresInSeconds,
      userId: userId,
      authClient: client,
    );
  }

  @override
  Future<auth.AccessToken> getAccessToken() async {
    // Refresh if needed
    if (isTokenExpired) {
      await _refreshIdToken();
    }

    // Return the ID token wrapped as an AccessToken
    return auth.AccessToken(
      'Bearer',
      _currentIdToken,
      _tokenExpiresAt.toUtc(),
    );
  }

  /// Force refresh the ID token.
  Future<void> forceRefresh() async {
    await _refreshIdToken();
  }

  /// Get the current refresh token (for saving session state).
  /// Returns null if no refresh token is available (e.g., custom token auth).
  String? get refreshTokenForSaving => _refreshToken;

  /// Get the token expiration time (for saving session state).
  DateTime get expiresAt => _tokenExpiresAt;

  Future<void> _refreshIdToken() async {
    if (_refreshToken == null) {
      throw StateError(
        'Cannot refresh token: No refresh token available. '
        'This auth method (e.g., custom token) does not support token refresh. '
        'Re-authenticate to get a new ID token.',
      );
    }

    final result = await _authClient.refreshToken(_refreshToken!);

    _currentIdToken = result.idToken;
    _refreshToken = result.refreshToken;
    _tokenExpiresAt = DateTime.now().add(Duration(seconds: result.expiresIn));
  }

  /// Delete the user account associated with this provider.
  Future<void> deleteAccount() async {
    // Ensure we have a valid token
    if (isTokenExpired) {
      await _refreshIdToken();
    }
    await _authClient.deleteAccount(_currentIdToken);
  }

  /// Close the HTTP client.
  void close() {
    _authClient.close();
  }
}
