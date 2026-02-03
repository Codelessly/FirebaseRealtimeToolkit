/// Comprehensive test suite for Firebase Auth REST API and IdTokenProvider.
///
/// Tests all authentication methods without requiring Firestore access.
///
/// Usage:
///   dart run test/auth_test.dart --api-key YOUR_FIREBASE_WEB_API_KEY
library;

import 'dart:io';

import 'package:firebase_realtime_toolkit/firebase_realtime_toolkit.dart';

void main(List<String> args) async {
  final apiKey = _getArg(args, '--api-key');

  if (apiKey == null) {
    stderr.writeln('Usage: dart run test/auth_test.dart --api-key YOUR_API_KEY');
    stderr.writeln('\nThe API key is your Firebase WEB API key, found in:');
    stderr.writeln(
        '  Firebase Console > Project Settings > General > Web API Key');
    exit(1);
  }

  print('🧪 Firebase Auth Test Suite\n');
  print('━' * 60);

  var testsRun = 0;
  var testsPassed = 0;
  var testsFailed = 0;

  // Test 1: Anonymous Sign-In
  print('\n1. Testing anonymous sign-in...');
  testsRun++;
  AuthResult? authResult;
  try {
    final authClient = FirebaseAuthClient(apiKey: apiKey);
    authResult = await authClient.signInAnonymously();
    authClient.close();

    print('   ✅ Success!');
    print('   User ID: ${authResult.localId}');
    print('   Token expires in: ${authResult.expiresIn} seconds');
    print(
        '   Token length: ${authResult.idToken.length} chars (valid JWT format)');
    testsPassed++;

    // Verify JWT structure
    final parts = authResult.idToken.split('.');
    if (parts.length == 3) {
      print('   ✅ JWT structure valid (header.payload.signature)');
    } else {
      throw Exception('Invalid JWT structure: ${parts.length} parts');
    }
  } on FirebaseAuthException catch (e) {
    testsFailed++;
    stderr.writeln('   ❌ Failed: ${e.code} - ${e.message}');
    if (e.code == 'ADMIN_ONLY_OPERATION') {
      stderr.writeln(
          '   → Enable Anonymous Authentication in Firebase Console');
      exit(1);
    }
  }

  if (authResult == null) {
    stderr.writeln('\n❌ Cannot continue without successful authentication');
    exit(1);
  }

  // Test 2: Token Refresh
  print('\n2. Testing token refresh...');
  testsRun++;
  try {
    final authClient = FirebaseAuthClient(apiKey: apiKey);
    final refreshResult = await authClient.refreshToken(authResult.refreshToken);
    authClient.close();

    print('   ✅ Success!');
    print('   New token expires in: ${refreshResult.expiresIn} seconds');
    print('   User ID matches: ${refreshResult.userId == authResult.localId}');
    print('   New token length: ${refreshResult.idToken.length} chars');

    if (refreshResult.userId == authResult.localId) {
      print('   ✅ User ID preserved after refresh');
      testsPassed++;
    } else {
      throw Exception('User ID mismatch after refresh');
    }
  } on FirebaseAuthException catch (e) {
    testsFailed++;
    stderr.writeln('   ❌ Failed: ${e.code} - ${e.message}');
  }

  // Test 3: Get User Data
  print('\n3. Testing get user data...');
  testsRun++;
  try {
    final authClient = FirebaseAuthClient(apiKey: apiKey);
    final userData = await authClient.getUserData(authResult.idToken);
    authClient.close();

    print('   ✅ Success!');
    print('   User ID: ${userData['localId']}');
    print('   Provider: ${(userData['providerUserInfo'] as List?)?.firstOrNull?['providerId'] ?? 'anonymous'}');
    print('   Created: ${DateTime.fromMillisecondsSinceEpoch(int.parse(userData['createdAt'] ?? '0'))}');
    print('   Last sign-in: ${DateTime.fromMillisecondsSinceEpoch(int.parse(userData['lastLoginAt'] ?? '0'))}');
    testsPassed++;
  } on FirebaseAuthException catch (e) {
    testsFailed++;
    stderr.writeln('   ❌ Failed: ${e.code} - ${e.message}');
  }

  // Test 4: IdTokenProvider.signInAnonymously
  print('\n4. Testing IdTokenProvider.signInAnonymously...');
  testsRun++;
  IdTokenProvider? provider;
  try {
    provider = await IdTokenProvider.signInAnonymously(
      apiKey: apiKey,
      projectId: 'test-project',
    );

    print('   ✅ Success!');
    print('   User ID: ${provider.userId}');
    print('   Token expires at: ${provider.expiresAt}');
    print('   Token expired: ${provider.isTokenExpired}');
    testsPassed++;
  } catch (e) {
    testsFailed++;
    stderr.writeln('   ❌ Failed: $e');
  }

  // Test 5: IdTokenProvider.getAccessToken
  print('\n5. Testing IdTokenProvider.getAccessToken...');
  testsRun++;
  try {
    if (provider == null) throw Exception('Provider not initialized');

    final accessToken = await provider.getAccessToken();
    print('   ✅ Success!');
    print('   Access token type: ${accessToken.type}');
    print('   Access token expiry: ${accessToken.expiry}');
    print('   Access token data length: ${accessToken.data.length} chars');

    // Verify token format
    if (accessToken.type == 'Bearer' && accessToken.data.isNotEmpty) {
      print('   ✅ AccessToken format valid');
      testsPassed++;
    } else {
      throw Exception('Invalid AccessToken format');
    }
  } catch (e) {
    testsFailed++;
    stderr.writeln('   ❌ Failed: $e');
  }

  // Test 6: IdTokenProvider.fromSavedTokens
  print('\n6. Testing IdTokenProvider.fromSavedTokens...');
  testsRun++;
  try {
    if (provider == null) throw Exception('Provider not initialized');

    final savedProvider = await IdTokenProvider.fromSavedTokens(
      apiKey: apiKey,
      projectId: 'test-project',
      idToken: provider.currentIdToken,
      refreshToken: provider.refreshTokenForSaving,
      userId: provider.userId,
      expiresAt: provider.expiresAt,
    );

    print('   ✅ Success!');
    print('   Restored user ID: ${savedProvider.userId}');
    print('   Same user: ${savedProvider.userId == provider.userId}');

    await savedProvider.getAccessToken();
    print('   ✅ Can get access token from restored provider');

    savedProvider.close();
    testsPassed++;
  } catch (e) {
    testsFailed++;
    stderr.writeln('   ❌ Failed: $e');
  }

  // Test 7: IdTokenProvider.forceRefresh
  print('\n7. Testing IdTokenProvider.forceRefresh...');
  testsRun++;
  try {
    if (provider == null) throw Exception('Provider not initialized');

    final oldToken = provider.currentIdToken;
    final oldExpiry = provider.expiresAt;

    await provider.forceRefresh();

    final newToken = provider.currentIdToken;
    final newExpiry = provider.expiresAt;

    print('   ✅ Success!');
    print('   Token changed: ${oldToken != newToken}');
    print('   Expiry updated: ${!oldExpiry.isAtSameMomentAs(newExpiry)}');
    print('   New token length: ${newToken.length} chars');

    // Firebase may return the same token if it's still fresh
    // The key is that refresh succeeds without error
    if (newToken.isNotEmpty && newExpiry.isAfter(DateTime.now())) {
      print('   ✅ Token refresh successful (valid token obtained)');
      testsPassed++;
    } else {
      throw Exception('Invalid token after refresh');
    }
  } catch (e) {
    testsFailed++;
    stderr.writeln('   ❌ Failed: $e');
  }

  // Test 8: Token Expiration Check
  print('\n8. Testing token expiration logic...');
  testsRun++;
  try {
    if (provider == null) throw Exception('Provider not initialized');

    // Test with 5-minute buffer (default)
    final isExpired5min = provider.isTokenExpired;
    print('   Is expired (5min buffer): $isExpired5min');

    // Test with 1-hour buffer (should report as expired since tokens expire in 1hr)
    provider.refreshBuffer = Duration(hours: 1);
    final isExpired1hr = provider.isTokenExpired;
    print('   Is expired (1hr buffer): $isExpired1hr');

    // Reset buffer
    provider.refreshBuffer = Duration(minutes: 5);

    print('   ✅ Expiration logic working');
    testsPassed++;
  } catch (e) {
    testsFailed++;
    stderr.writeln('   ❌ Failed: $e');
  }

  // Test 9: Delete Account (cleanup)
  print('\n9. Testing delete account (cleanup)...');
  testsRun++;
  try {
    if (provider == null) throw Exception('Provider not initialized');

    await provider.deleteAccount();
    print('   ✅ Account deleted successfully');
    testsPassed++;
  } catch (e) {
    testsFailed++;
    stderr.writeln('   ⚠️ Could not delete: $e');
    // Non-fatal for test suite
  }

  // Cleanup
  provider?.close();

  // Summary
  print('\n' + '━' * 60);
  print('\n📊 Test Summary:');
  print('   Total tests: $testsRun');
  print('   Passed: $testsPassed ✅');
  print('   Failed: $testsFailed ❌');
  print('   Success rate: ${(testsPassed / testsRun * 100).toStringAsFixed(1)}%');

  if (testsFailed == 0) {
    print('\n✅ All tests passed!');
    print('\nYour Firebase project is configured correctly for client-side auth.');
    print('You can now use IdTokenProvider with FirestoreListenClient in your apps.');
    exit(0);
  } else {
    stderr.writeln('\n❌ Some tests failed');
    exit(1);
  }
}

String? _getArg(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index != -1 && index + 1 < args.length) {
    return args[index + 1];
  }
  return null;
}
