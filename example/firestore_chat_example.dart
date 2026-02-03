/// Example: Real-time chat/status monitoring using Firestore with anonymous auth.
///
/// This demonstrates a practical use case where:
/// 1. Users sign in anonymously
/// 2. Listen to a shared status/chat document
/// 3. See updates in real-time as others modify the document
///
/// Perfect for:
/// - Presence indicators ("User X is online")
/// - Live status dashboards
/// - Simple chat applications
/// - Collaborative editing indicators
///
/// Usage:
///   dart run example/firestore_chat_example.dart \
///     --api-key YOUR_FIREBASE_WEB_API_KEY \
///     --project your-project-id \
///     --room public/chat
///
/// Prerequisites:
///   1. Enable Anonymous Authentication
///   2. Configure Firestore Security Rules:
///
///      rules_version = '2';
///      service cloud.firestore {
///        match /databases/{database}/documents {
///          match /public/{document=**} {
///            allow read: if request.auth != null;
///            allow write: if request.auth != null;
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
  final room = _getArg(args, '--room') ?? 'public/chat';

  if (apiKey == null || projectId == null) {
    stderr.writeln('Usage: dart run example/firestore_chat_example.dart '
        '--api-key YOUR_API_KEY --project YOUR_PROJECT_ID [--room public/chat]');
    exit(1);
  }

  print('💬 Firestore Real-time Chat Example\n');
  print('━' * 60);

  // Step 1: Sign in anonymously
  print('\n1. Signing in anonymously...');
  final tokenProvider = await IdTokenProvider.signInAnonymously(
    apiKey: apiKey,
    projectId: projectId,
  );
  print('   ✅ Signed in as ${tokenProvider.userId}');
  print('   Token expires at: ${tokenProvider.expiresAt.toLocal()}');

  // Step 2: Connect to Firestore
  print('\n2. Connecting to Firestore room: $room');
  final client = FirestoreListenClient(
    projectId: projectId,
    tokenProvider: tokenProvider,
  );

  // Step 3: Start listening
  print('   Starting listener...');
  var messageCount = 0;

  final subscription = client.listenDocument(room).listen(
    (response) {
      if (response.hasTargetChange()) {
        final change = response.targetChange;
        if (change.targetChangeType.toString().contains('ADD')) {
          print('   ✅ Connected to room');
        } else if (change.targetChangeType.toString().contains('REMOVE')) {
          if (change.hasCause()) {
            stderr.writeln('\n   ❌ Connection lost:');
            stderr.writeln('      ${change.cause.message}');
            if (change.cause.code == 7) {
              stderr.writeln(
                  '      → Check that security rules allow authenticated read/write');
            }
          }
        }
      }

      if (response.hasDocumentChange()) {
        messageCount++;
        final doc = response.documentChange.document;
        final fields = doc.fields;

        print('\n   📨 Update #$messageCount:');
        if (fields.containsKey('message')) {
          print('      Message: "${fields['message']!.stringValue}"');
        }
        if (fields.containsKey('author')) {
          print('      Author: ${fields['author']!.stringValue}');
        }
        if (fields.containsKey('timestamp')) {
          final ts = fields['timestamp']!.timestampValue;
          final dateTime =
              DateTime.fromMillisecondsSinceEpoch(ts.seconds.toInt() * 1000);
          print('      Time: ${dateTime.toLocal()}');
        }
      }
    },
    onError: (error) {
      stderr.writeln('\n   ❌ Error: $error');
    },
  );

  // Step 4: Post a message to demonstrate write capability
  print('\n3. Posting a test message...');
  try {
    await _postMessage(
      projectId: projectId,
      documentPath: room,
      idToken: tokenProvider.currentIdToken,
      message: 'Hello from ${tokenProvider.userId.substring(0, 8)}!',
      author: tokenProvider.userId.substring(0, 8),
    );
    print('   ✅ Message posted');
  } catch (e) {
    stderr.writeln('   ⚠️ Could not post message: $e');
    stderr.writeln(
        '      This is expected if security rules don\'t allow writes');
  }

  // Step 5: Monitor for changes
  print('\n4. Monitoring room for activity...');
  print('   Press Ctrl+C to exit');
  print('   Waiting for messages...\n');
  print('━' * 60);

  // Keep running until interrupted
  await ProcessSignal.sigint.watch().first;

  // Cleanup
  print('\n\n5. Cleaning up...');
  await subscription.cancel();
  await client.close();
  tokenProvider.close();

  print('   ✅ Disconnected');
  print('\n📊 Session Summary:');
  print('   User ID: ${tokenProvider.userId}');
  print('   Room: $room');
  print('   Messages received: $messageCount');
  print('\nGoodbye! 👋');
}

Future<void> _postMessage({
  required String projectId,
  required String documentPath,
  required String idToken,
  required String message,
  required String author,
}) async {
  final normalizedPath =
      documentPath.startsWith('/') ? documentPath.substring(1) : documentPath;

  final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$normalizedPath');

  final body = jsonEncode({
    'fields': {
      'message': {'stringValue': message},
      'author': {'stringValue': author},
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

String? _getArg(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index != -1 && index + 1 < args.length) {
    return args[index + 1];
  }
  return null;
}
