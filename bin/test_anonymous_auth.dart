/// Simple test to verify anonymous authentication works.
///
/// Usage:
///   dart run bin/test_anonymous_auth.dart --api-key YOUR_FIREBASE_WEB_API_KEY
///
/// This tests only the authentication flow, not Firestore access.
/// Use this to verify your API key works before testing Firestore.
library;

import 'dart:io';

import 'package:firebase_realtime_toolkit/firebase_realtime_toolkit.dart';

void main(List<String> args) async {
  final apiKey = _getArg(args, '--api-key');

  if (apiKey == null) {
    stderr.writeln('Usage: dart run bin/test_anonymous_auth.dart --api-key YOUR_API_KEY');
    stderr.writeln('\nThe API key is your Firebase WEB API key, found in:');
    stderr.writeln('  Firebase Console > Project Settings > General > Web API Key');
    exit(1);
  }

  print('Testing Firebase Auth REST API...\n');

  final authClient = FirebaseAuthClient(apiKey: apiKey);

  // Test 1: Sign in anonymously
  print('1. Testing anonymous sign-in...');
  AuthResult? authResult;
  try {
    authResult = await authClient.signInAnonymously();
    print('   ✅ Success!');
    print('   User ID: ${authResult.localId}');
    print('   Token expires in: ${authResult.expiresIn} seconds');
    print('   ID Token (first 50 chars): ${authResult.idToken.substring(0, 50)}...');
  } on FirebaseAuthException catch (e) {
    stderr.writeln('   ❌ Failed: ${e.code}');
    if (e.code == 'ADMIN_ONLY_OPERATION') {
      stderr.writeln('   → Enable Anonymous Authentication in Firebase Console');
      stderr.writeln('   → Go to: Authentication > Sign-in method > Anonymous > Enable');
    }
    exit(1);
  }

  // Test 2: Refresh token
  print('\n2. Testing token refresh...');
  try {
    final refreshResult = await authClient.refreshToken(authResult.refreshToken);
    print('   ✅ Success!');
    print('   New token expires in: ${refreshResult.expiresIn} seconds');
    print('   Same user ID: ${refreshResult.userId == authResult.localId}');
  } on FirebaseAuthException catch (e) {
    stderr.writeln('   ❌ Failed: ${e.code}');
    stderr.writeln('   ${e.message}');
    exit(1);
  }

  // Test 3: Get user data
  print('\n3. Testing get user data...');
  try {
    final userData = await authClient.getUserData(authResult.idToken);
    print('   ✅ Success!');
    print('   User ID: ${userData['localId']}');
    print('   Provider: ${(userData['providerUserInfo'] as List?)?.firstOrNull?['providerId'] ?? 'anonymous'}');
    print('   Created: ${DateTime.fromMillisecondsSinceEpoch(int.parse(userData['createdAt'] ?? '0'))}');
  } on FirebaseAuthException catch (e) {
    stderr.writeln('   ❌ Failed: ${e.code}');
    stderr.writeln('   ${e.message}');
    exit(1);
  }

  // Test 4: IdTokenProvider integration
  print('\n4. Testing IdTokenProvider...');
  try {
    final provider = await IdTokenProvider.fromSavedTokens(
      apiKey: apiKey,
      projectId: 'test-project',
      idToken: authResult.idToken,
      refreshToken: authResult.refreshToken,
      userId: authResult.localId,
      expiresAt: authResult.expiresAt,
    );

    final accessToken = await provider.getAccessToken();
    print('   ✅ Success!');
    print('   Access token type: ${accessToken.type}');
    print('   Expires: ${accessToken.expiry}');

    provider.close();
  } catch (e) {
    stderr.writeln('   ❌ Failed: $e');
    exit(1);
  }

  // Test 5: Delete user (cleanup)
  print('\n5. Cleaning up (deleting test user)...');
  try {
    await authClient.deleteAccount(authResult.idToken);
    print('   ✅ User deleted');
  } on FirebaseAuthException catch (e) {
    stderr.writeln('   ⚠️ Could not delete: ${e.code}');
  }

  authClient.close();

  print('\n✅ All tests passed! Anonymous authentication is working.');
  print('\nYou can now use IdTokenProvider with FirestoreListenClient:');
  print('''
  final provider = await IdTokenProvider.signInAnonymously(
    apiKey: '$apiKey',
    projectId: 'YOUR_PROJECT_ID',
  );

  final client = FirestoreListenClient(
    projectId: 'YOUR_PROJECT_ID',
    tokenProvider: provider,
  );

  await for (final response in client.listenDocument('public/status')) {
    print('Update: \$response');
  }
''');
}

String? _getArg(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index != -1 && index + 1 < args.length) {
    return args[index + 1];
  }
  return null;
}
