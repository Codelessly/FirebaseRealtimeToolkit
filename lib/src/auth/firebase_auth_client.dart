import 'dart:convert';

import 'package:http/http.dart' as http;

/// Extract user ID from JWT ID token.
String _extractUserIdFromIdToken(String idToken) {
  // JWT format: header.payload.signature
  final parts = idToken.split('.');
  if (parts.length != 3) {
    throw FormatException('Invalid JWT format');
  }

  // Decode base64url payload
  String payload = parts[1];
  // Add padding if needed
  switch (payload.length % 4) {
    case 2:
      payload += '==';
      break;
    case 3:
      payload += '=';
      break;
  }
  // Replace URL-safe chars
  payload = payload.replaceAll('-', '+').replaceAll('_', '/');

  final jsonStr = utf8.decode(base64.decode(payload));
  final claims = jsonDecode(jsonStr) as Map<String, dynamic>;

  // Try different field names (sub, user_id, uid)
  return claims['sub'] as String? ??
      claims['user_id'] as String? ??
      claims['uid'] as String? ??
      '';
}

/// Response from Firebase Auth REST API sign-in endpoints.
class AuthResult {
  AuthResult({
    required this.idToken,
    this.refreshToken,
    required this.expiresIn,
    required this.localId,
    this.email,
    this.isNewUser = false,
  });

  /// The Firebase ID token (JWT) - valid for 1 hour.
  final String idToken;

  /// The refresh token - use to get new ID tokens.
  /// May be null for some auth methods like custom token signin.
  final String? refreshToken;

  /// Token expiration time in seconds (typically 3600).
  final int expiresIn;

  /// The user's unique ID (uid).
  final String localId;

  /// The user's email (if available).
  final String? email;

  /// Whether this is a newly created user.
  final bool isNewUser;

  /// When this token was obtained.
  final DateTime obtainedAt = DateTime.now();

  /// When this token expires.
  DateTime get expiresAt => obtainedAt.add(Duration(seconds: expiresIn));

  /// Whether the token is expired or will expire within the buffer time.
  bool isExpired({Duration buffer = const Duration(minutes: 5)}) {
    return DateTime.now().add(buffer).isAfter(expiresAt);
  }

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final idToken = json['idToken'] as String;

    // localId may not be present in custom token responses
    // Extract from JWT if not provided
    final localId = json['localId'] as String? ??
        _extractUserIdFromIdToken(idToken);

    return AuthResult(
      idToken: idToken,
      refreshToken: json['refreshToken'] as String?,
      expiresIn: int.parse(json['expiresIn'] as String),
      localId: localId,
      email: json['email'] as String?,
      isNewUser: json['isNewUser'] == true,
    );
  }
}

/// Response from token refresh endpoint.
class RefreshResult {
  RefreshResult({
    required this.idToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.userId,
  });

  final String idToken;
  final String refreshToken;
  final int expiresIn;
  final String userId;

  final DateTime obtainedAt = DateTime.now();

  DateTime get expiresAt => obtainedAt.add(Duration(seconds: expiresIn));

  bool isExpired({Duration buffer = const Duration(minutes: 5)}) {
    return DateTime.now().add(buffer).isAfter(expiresAt);
  }

  factory RefreshResult.fromJson(Map<String, dynamic> json) {
    return RefreshResult(
      idToken: json['id_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: int.parse(json['expires_in'] as String),
      userId: json['user_id'] as String,
    );
  }
}

/// Firebase Auth error from REST API.
class FirebaseAuthException implements Exception {
  FirebaseAuthException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'FirebaseAuthException: $code - $message';

  factory FirebaseAuthException.fromJson(Map<String, dynamic> json) {
    final error = json['error'] as Map<String, dynamic>;
    final code = error['message'] as String? ?? 'UNKNOWN_ERROR';
    final message = error['message'] as String? ?? 'Unknown error';
    return FirebaseAuthException(code, message);
  }
}

/// Firebase Auth REST API client for client-side authentication.
///
/// This allows authentication without service account credentials,
/// using Firebase's public REST API endpoints.
///
/// See: https://firebase.google.com/docs/reference/rest/auth
class FirebaseAuthClient {
  FirebaseAuthClient({
    required this.apiKey,
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  /// Firebase Web API Key (found in Firebase Console > Project Settings).
  final String apiKey;

  final http.Client _client;

  static const _identityToolkitBase =
      'https://identitytoolkit.googleapis.com/v1';
  static const _secureTokenBase = 'https://securetoken.googleapis.com/v1';

  /// Sign in anonymously, creating a new anonymous user.
  ///
  /// Returns an [AuthResult] with ID token and refresh token.
  /// The user will have a unique UID but no email/password.
  ///
  /// Security rules can grant anonymous users scoped permissions.
  Future<AuthResult> signInAnonymously() async {
    final url = Uri.parse('$_identityToolkitBase/accounts:signUp?key=$apiKey');

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'returnSecureToken': true}),
    );

    return _handleAuthResponse(response);
  }

  /// Sign in with email and password.
  ///
  /// The user must already exist (created via Firebase Console or signUp).
  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(
        '$_identityToolkitBase/accounts:signInWithPassword?key=$apiKey');

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    return _handleAuthResponse(response);
  }

  /// Sign up a new user with email and password.
  ///
  /// Creates a new user account and returns authentication tokens.
  Future<AuthResult> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_identityToolkitBase/accounts:signUp?key=$apiKey');

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    return _handleAuthResponse(response);
  }

  /// Sign in with a custom token generated by the admin SDK.
  ///
  /// This is useful when you have a server that generates custom tokens
  /// for specific users with custom claims.
  Future<AuthResult> signInWithCustomToken(String customToken) async {
    final url = Uri.parse(
        '$_identityToolkitBase/accounts:signInWithCustomToken?key=$apiKey');

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': customToken,
        'returnSecureToken': true,
      }),
    );

    return _handleAuthResponse(response);
  }

  /// Refresh an expired ID token using the refresh token.
  ///
  /// ID tokens expire after 1 hour. Use this to get a new ID token
  /// without requiring the user to sign in again.
  Future<RefreshResult> refreshToken(String refreshToken) async {
    final url = Uri.parse('$_secureTokenBase/token?key=$apiKey');

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'grant_type=refresh_token&refresh_token=$refreshToken',
    );

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw FirebaseAuthException.fromJson(json);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return RefreshResult.fromJson(json);
  }

  /// Get user data for an ID token.
  Future<Map<String, dynamic>> getUserData(String idToken) async {
    final url = Uri.parse('$_identityToolkitBase/accounts:lookup?key=$apiKey');

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw FirebaseAuthException.fromJson(json);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final users = json['users'] as List?;
    if (users == null || users.isEmpty) {
      throw FirebaseAuthException('USER_NOT_FOUND', 'User not found');
    }
    return users.first as Map<String, dynamic>;
  }

  /// Delete the current user account.
  Future<void> deleteAccount(String idToken) async {
    final url = Uri.parse('$_identityToolkitBase/accounts:delete?key=$apiKey');

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw FirebaseAuthException.fromJson(json);
    }
  }

  AuthResult _handleAuthResponse(http.Response response) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw FirebaseAuthException.fromJson(json);
    }

    return AuthResult.fromJson(json);
  }

  void close() {
    _client.close();
  }
}
