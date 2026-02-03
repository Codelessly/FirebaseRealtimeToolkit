/// Read-only integration test for Firestore realtime listener.
///
/// This test verifies the listener works by connecting to an existing
/// document that gets updated externally (e.g., by a service account script).
///
/// This is useful when:
/// - Security rules don't allow anonymous writes
/// - You want to test only the listening functionality
/// - Testing in production environments
///
/// Usage:
///   # Terminal 1: Start the listener
///   dart run test/integration_test_readonly.dart \
///     --api-key YOUR_API_KEY \
///     --project your-project-id \
///     --document test/watch_doc
///
///   # Terminal 2: Update the document with service account
///   dart run firebase_realtime_toolkit:firestore_write \
///     --service-account /path/to/service-account.json \
///     --project your-project-id \
///     --document test/watch_doc \
///     --field value \
///     --value "update_$(date +%s)"
library;

import 'dart:async';
import 'dart:io';

import 'package:firebase_realtime_toolkit/firebase_realtime_toolkit.dart';

void main(List<String> args) async {
  final apiKey = _getArg(args, '--api-key');
  final projectId = _getArg(args, '--project');
  final documentPath = _getArg(args, '--document') ?? 'test/watch_doc';
  final timeoutSeconds =
      int.tryParse(_getArg(args, '--timeout') ?? '60') ?? 60;

  if (apiKey == null || projectId == null) {
    stderr.writeln('Usage: dart run test/integration_test_readonly.dart '
        '--api-key YOUR_API_KEY --project YOUR_PROJECT_ID [--document path] [--timeout 60]');
    exit(1);
  }

  print('🧪 Read-Only Integration Test: Firestore Realtime Listener\n');

  // Step 1: Sign in anonymously
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

  // Step 2: Create Firestore client and start listening
  print('\n2. Starting Firestore listener on: $documentPath');
  final client = FirestoreListenClient(
    projectId: projectId,
    tokenProvider: tokenProvider,
  );

  var updateCount = 0;
  final subscription = client.listenDocument(documentPath).listen(
    (response) {
      if (response.hasTargetChange()) {
        final change = response.targetChange;
        print('   [Target] ${change.targetChangeType}');

        if (change.targetChangeType.toString().contains('REMOVE')) {
          if (change.hasCause()) {
            stderr.writeln('   ❌ Target removed with error:');
            stderr.writeln('      Code: ${change.cause.code}');
            stderr.writeln('      Message: ${change.cause.message}');

            if (change.cause.code == 7) {
              stderr.writeln('\n   → PERMISSION_DENIED: Check Firestore Security Rules');
              stderr.writeln('      Rules should allow: allow read: if request.auth != null;');
            }
          }
        }
      }

      if (response.hasDocumentChange()) {
        updateCount++;
        final doc = response.documentChange.document;
        final changeType = response.documentChange.targetIds.isEmpty
            ? 'INITIAL'
            : 'UPDATE';

        print('\n   [$changeType #$updateCount] Document: ${doc.name}');
        print('   Fields:');
        for (final entry in doc.fields.entries) {
          final value = _formatValue(entry.value);
          print('     ${entry.key}: $value');
        }
        print('   Update time: ${doc.updateTime}');
      }

      if (response.hasDocumentDelete()) {
        print('\n   [DELETE] ${response.documentDelete.document}');
      }

      if (response.hasDocumentRemove()) {
        print('\n   [REMOVE] ${response.documentRemove.document}');
      }
    },
    onError: (error) {
      stderr.writeln('\n   ❌ Listener error: $error');
    },
    onDone: () {
      print('\n   ℹ️ Listener closed');
    },
  );

  print('   ✅ Listener started');
  print('\n3. Watching for updates (timeout: ${timeoutSeconds}s)...');
  print('   Use firestore_write to update the document in another terminal\n');

  // Wait for the timeout duration
  await Future.delayed(Duration(seconds: timeoutSeconds));

  // Cleanup
  print('\n4. Shutting down...');
  await subscription.cancel();
  await client.close();
  tokenProvider.close();

  print('\n✅ Test completed!');
  print('\nSummary:');
  print('  - Anonymous authentication: ✅');
  print('  - Firestore listener connection: ✅');
  print('  - Updates received: $updateCount');

  if (updateCount == 0) {
    print('\n⚠️ No updates received. This could mean:');
    print('   1. Document doesn\'t exist (expected on first run)');
    print('   2. No updates were made during the test window');
    print('   3. Security rules may be blocking access');
    print('\nTo test updates, run firestore_write in another terminal:');
    print('  dart run firebase_realtime_toolkit:firestore_write \\');
    print('    --service-account /path/to/service-account.json \\');
    print('    --project $projectId \\');
    print('    --document $documentPath \\');
    print('    --field value \\');
    print('    --value "test_\$(date +%s)"');
  }
}

String _formatValue(dynamic value) {
  if (value == null) return 'null';

  final type = value.runtimeType.toString();
  if (type.contains('Value')) {
    if (value.hasStringValue()) return '"${value.stringValue}"';
    if (value.hasIntegerValue()) return value.integerValue.toString();
    if (value.hasDoubleValue()) return value.doubleValue.toString();
    if (value.hasBooleanValue()) return value.booleanValue.toString();
    if (value.hasNullValue()) return 'null';
    if (value.hasTimestampValue()) {
      final ts = value.timestampValue;
      return 'Timestamp(${ts.seconds}.${ts.nanos})';
    }
    if (value.hasMapValue()) {
      final map = value.mapValue.fields;
      return '{${map.entries.map((e) => '${e.key}: ${_formatValue(e.value)}').join(', ')}}';
    }
    if (value.hasArrayValue()) {
      final arr = value.arrayValue.values;
      return '[${arr.map(_formatValue).join(', ')}]';
    }
  }

  return value.toString();
}

String? _getArg(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index != -1 && index + 1 < args.length) {
    return args[index + 1];
  }
  return null;
}
