/// Test CLI for Firestore realtime listener with anonymous authentication.
///
/// This demonstrates listening to Firestore documents WITHOUT a service account,
/// using Firebase Auth's anonymous sign-in instead.
///
/// Usage:
///   dart run firebase_realtime_toolkit:firestore_listen_anonymous \
///     --api-key YOUR_FIREBASE_WEB_API_KEY \
///     --project your-project-id \
///     --document collection/docId
///
/// Prerequisites:
///   1. Enable Anonymous Authentication in Firebase Console
///   2. Configure Firestore Security Rules to allow anonymous access:
///
///      rules_version = '2';
///      service cloud.firestore {
///        match /databases/{database}/documents {
///          match /public/{document=**} {
///            allow read: if request.auth != null;
///          }
///        }
///      }
library;

import 'dart:io';

import 'package:firebase_realtime_toolkit/firebase_realtime_toolkit.dart';

void main(List<String> args) async {
  final parsed = _parseArgs(args);

  if (parsed['help'] == true) {
    _printUsage();
    exit(0);
  }

  final apiKey = parsed['api-key'] as String?;
  final projectId = parsed['project'] as String?;
  final document = parsed['document'] as String?;

  if (apiKey == null || projectId == null || document == null) {
    stderr.writeln('Error: Missing required arguments');
    _printUsage();
    exit(1);
  }

  print('🔐 Signing in anonymously...');

  IdTokenProvider tokenProvider;
  try {
    tokenProvider = await IdTokenProvider.signInAnonymously(
      apiKey: apiKey,
      projectId: projectId,
    );
    print('✅ Signed in anonymously');
    print('   User ID: ${tokenProvider.userId}');
  } on FirebaseAuthException catch (e) {
    stderr.writeln('❌ Authentication failed: ${e.code}');
    stderr.writeln('   ${e.message}');
    if (e.code == 'ADMIN_ONLY_OPERATION') {
      stderr.writeln('\n   Make sure Anonymous Authentication is enabled in '
          'Firebase Console > Authentication > Sign-in method');
    }
    exit(1);
  }

  print('\n📡 Listening to document: $document');
  print('   (Ctrl+C to stop)\n');

  final client = FirestoreListenClient(
    projectId: projectId,
    tokenProvider: tokenProvider,
  );

  try {
    await for (final response in client.listenDocument(document)) {
      if (response.hasTargetChange()) {
        final change = response.targetChange;
        print('[Target] ${change.targetChangeType} - '
            'targetIds: ${change.targetIds}');
      }

      if (response.hasDocumentChange()) {
        final change = response.documentChange;
        final doc = change.document;
        print('\n[Document Change]');
        print('  Path: ${doc.name}');
        print('  Fields:');
        for (final entry in doc.fields.entries) {
          final value = _formatValue(entry.value);
          print('    ${entry.key}: $value');
        }
      }

      if (response.hasDocumentDelete()) {
        final delete = response.documentDelete;
        print('\n[Document Deleted] ${delete.document}');
      }
    }
  } on Exception catch (e) {
    stderr.writeln('\n❌ Error: $e');

    // Check for permission denied errors
    final errorStr = e.toString().toLowerCase();
    if (errorStr.contains('permission') || errorStr.contains('denied')) {
      stderr.writeln('\n   This likely means your Firestore Security Rules '
          'don\'t allow access.');
      stderr.writeln('   Make sure you have rules like:');
      stderr.writeln('''

   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /$document {
         allow read: if request.auth != null;
       }
     }
   }
''');
    }
    exit(1);
  } finally {
    await client.close();
    tokenProvider.close();
  }
}

String _formatValue(dynamic value) {
  if (value == null) return 'null';

  // Handle Firestore Value protobuf
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

Map<String, dynamic> _parseArgs(List<String> args) {
  final result = <String, dynamic>{};

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];

    if (arg == '--help' || arg == '-h') {
      result['help'] = true;
    } else if (arg == '--api-key' && i + 1 < args.length) {
      result['api-key'] = args[++i];
    } else if (arg == '--project' && i + 1 < args.length) {
      result['project'] = args[++i];
    } else if (arg == '--document' && i + 1 < args.length) {
      result['document'] = args[++i];
    }
  }

  return result;
}

void _printUsage() {
  print('''
Firestore Realtime Listener with Anonymous Authentication

Listen to Firestore documents WITHOUT a service account!

USAGE:
  dart run firebase_realtime_toolkit:firestore_listen_anonymous [OPTIONS]

OPTIONS:
  --api-key KEY      Firebase Web API Key (required)
                     Find in Firebase Console > Project Settings > General

  --project ID       Firebase Project ID (required)

  --document PATH    Document path to listen to (required)
                     Example: users/user123, public/status

  -h, --help         Show this help message

PREREQUISITES:
  1. Enable Anonymous Authentication:
     Firebase Console > Authentication > Sign-in method > Anonymous > Enable

  2. Configure Firestore Security Rules to allow anonymous read access:

     rules_version = '2';
     service cloud.firestore {
       match /databases/{database}/documents {
         match /public/{document=**} {
           allow read: if request.auth != null;
         }
       }
     }

EXAMPLE:
  dart run firebase_realtime_toolkit:firestore_listen_anonymous \\
    --api-key AIzaSyB1234567890abcdefg \\
    --project my-firebase-project \\
    --document public/status

NOTES:
  - The API key is your Firebase WEB API key, not a service account
  - Anonymous users get a unique UID, visible in Firebase Console
  - Security rules control what documents anonymous users can access
''');
}
