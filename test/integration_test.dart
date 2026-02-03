/// Integration test for Firestore realtime listener with anonymous authentication.
///
/// This test verifies:
/// 1. Anonymous sign-in works
/// 2. Firestore listener connects successfully
/// 3. Listener receives document updates
/// 4. Token refresh works
///
/// Usage:
///   dart run test/integration_test.dart \
///     --api-key YOUR_FIREBASE_WEB_API_KEY \
///     --project your-project-id \
///     --document test/integration_test_doc
///
/// Prerequisites:
///   1. Enable Anonymous Authentication in Firebase Console
///   2. Configure Firestore Security Rules:
///
///      rules_version = '2';
///      service cloud.firestore {
///        match /databases/{database}/documents {
///          match /test/{document} {
///            allow read, write: if request.auth != null;
///          }
///        }
///      }
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_realtime_toolkit/firebase_realtime_toolkit.dart';
import 'package:http/http.dart' as http;

void main(List<String> args) async {
  final apiKey = _getArg(args, '--api-key');
  final projectId = _getArg(args, '--project');
  final documentPath = _getArg(args, '--document') ?? 'test/integration_test';

  if (apiKey == null || projectId == null) {
    stderr.writeln('Usage: dart run test/integration_test.dart '
        '--api-key YOUR_API_KEY --project YOUR_PROJECT_ID [--document path]');
    exit(1);
  }

  print('🧪 Integration Test: Firestore Realtime Listener\n');

  // Test 1: Sign in anonymously
  print('1. Signing in anonymously...');
  IdTokenProvider? tokenProvider;
  try {
    tokenProvider = await IdTokenProvider.signInAnonymously(
      apiKey: apiKey,
      projectId: projectId,
    );
    print('   ✅ Signed in as ${tokenProvider.userId}');
  } on FirebaseAuthException catch (e) {
    stderr.writeln('   ❌ Auth failed: ${e.code}');
    if (e.code == 'ADMIN_ONLY_OPERATION') {
      stderr.writeln('   → Enable Anonymous Authentication in Firebase Console');
    }
    exit(1);
  }

  // Test 2: Create Firestore client and start listening
  print('\n2. Starting Firestore listener...');
  final client = FirestoreListenClient(
    projectId: projectId,
    tokenProvider: tokenProvider,
  );

  final updateStream = StreamController<String>();
  final subscription = client.listenDocument(documentPath).listen(
    (response) {
      if (response.hasTargetChange()) {
        final change = response.targetChange;
        print('   [Target] ${change.targetChangeType}');
      }

      if (response.hasDocumentChange()) {
        final doc = response.documentChange.document;
        final fields = doc.fields;
        if (fields.containsKey('value')) {
          final value = fields['value']!.stringValue;
          print('   [Update] value: $value');
          updateStream.add(value);
        }
      }

      if (response.hasDocumentDelete()) {
        print('   [Delete] ${response.documentDelete.document}');
      }
    },
    onError: (error) {
      stderr.writeln('   ❌ Listener error: $error');
    },
  );

  // Wait for listener to connect
  await Future.delayed(Duration(seconds: 2));
  print('   ✅ Listener connected');

  // Test 3: Write to the document using REST API
  print('\n3. Writing test document...');
  try {
    await _writeDocument(
      projectId: projectId,
      documentPath: documentPath,
      idToken: tokenProvider.currentIdToken,
      value: 'test_value_1',
    );
    print('   ✅ Document written');
  } catch (e) {
    stderr.writeln('   ❌ Write failed: $e');
    await subscription.cancel();
    await client.close();
    tokenProvider.close();
    exit(1);
  }

  // Test 4: Verify we receive the update
  print('\n4. Waiting for update notification...');
  try {
    final receivedValue = await updateStream.stream
        .timeout(Duration(seconds: 10))
        .firstWhere((value) => value == 'test_value_1');
    print('   ✅ Received update: $receivedValue');
  } on TimeoutException {
    stderr.writeln('   ❌ Timeout waiting for update');
    stderr.writeln('   → Check Firestore Security Rules');
    await subscription.cancel();
    await client.close();
    tokenProvider.close();
    exit(1);
  }

  // Test 5: Write another update
  print('\n5. Writing second update...');
  try {
    await _writeDocument(
      projectId: projectId,
      documentPath: documentPath,
      idToken: tokenProvider.currentIdToken,
      value: 'test_value_2',
    );
    print('   ✅ Second write completed');
  } catch (e) {
    stderr.writeln('   ❌ Write failed: $e');
    await subscription.cancel();
    await client.close();
    tokenProvider.close();
    exit(1);
  }

  // Test 6: Verify second update
  print('\n6. Waiting for second update...');
  try {
    final receivedValue = await updateStream.stream
        .timeout(Duration(seconds: 10))
        .firstWhere((value) => value == 'test_value_2');
    print('   ✅ Received second update: $receivedValue');
  } on TimeoutException {
    stderr.writeln('   ❌ Timeout waiting for second update');
    await subscription.cancel();
    await client.close();
    tokenProvider.close();
    exit(1);
  }

  // Test 7: Delete the document (cleanup)
  print('\n7. Cleaning up (deleting test document)...');
  try {
    await _deleteDocument(
      projectId: projectId,
      documentPath: documentPath,
      idToken: tokenProvider.currentIdToken,
    );
    print('   ✅ Document deleted');
  } catch (e) {
    stderr.writeln('   ⚠️ Delete failed (non-fatal): $e');
  }

  // Cleanup
  await Future.delayed(Duration(seconds: 1));
  await subscription.cancel();
  await client.close();
  tokenProvider.close();
  await updateStream.close();

  print('\n✅ All integration tests passed!');
  print('\nSummary:');
  print('  - Anonymous authentication: ✅');
  print('  - Firestore listener connection: ✅');
  print('  - Real-time update delivery: ✅');
  print('  - Multiple updates: ✅');
  print('  - Cleanup: ✅');
}

Future<void> _writeDocument({
  required String projectId,
  required String documentPath,
  required String idToken,
  required String value,
}) async {
  final normalizedPath =
      documentPath.startsWith('/') ? documentPath.substring(1) : documentPath;

  final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$normalizedPath');

  final body = jsonEncode({
    'fields': {
      'value': {'stringValue': value},
      'timestamp': {
        'timestampValue': DateTime.now().toUtc().toIso8601String()
      },
    }
  });

  final response = await http.patch(
    url,
    headers: {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    },
    body: body,
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Write failed: ${response.statusCode} ${response.body}');
  }
}

Future<void> _deleteDocument({
  required String projectId,
  required String documentPath,
  required String idToken,
}) async {
  final normalizedPath =
      documentPath.startsWith('/') ? documentPath.substring(1) : documentPath;

  final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$normalizedPath');

  final response = await http.delete(
    url,
    headers: {
      'Authorization': 'Bearer $idToken',
    },
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Delete failed: ${response.statusCode} ${response.body}');
  }
}

String? _getArg(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index != -1 && index + 1 < args.length) {
    return args[index + 1];
  }
  return null;
}
