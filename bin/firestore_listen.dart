import 'dart:async';
import 'dart:io';

import 'package:firebase_realtime_toolkit/firebase_realtime_toolkit.dart';

void main(List<String> args) async {
  final serviceAccount = _argValue(args, '--service-account');
  final projectId = _argValue(args, '--project');
  final documentPath = _argValue(args, '--document');
  final databaseId = _argValue(args, '--database') ?? '(default)';
  final durationSeconds =
      int.tryParse(_argValue(args, '--duration') ?? '0') ?? 0;

  if (serviceAccount == null || projectId == null || documentPath == null) {
    stderr.writeln(
        'Usage: firestore_listen --service-account <path> --project <id> --document <collection/doc> [--database (default)] [--duration 10]');
    exit(64);
  }

  final tokenProvider = ServiceAccountTokenProvider(serviceAccount);
  final client = FirestoreListenClient(
    projectId: projectId,
    databaseId: databaseId,
    tokenProvider: tokenProvider,
  );

  stdout.writeln('Listening to document $documentPath in project $projectId');

  final subscription = client
      .listenDocument(documentPath)
      .listen((event) => stdout.writeln(event));

  if (durationSeconds > 0) {
    await Future.delayed(Duration(seconds: durationSeconds));
    await subscription.cancel();
    await client.close();
  }
}

String? _argValue(List<String> args, String key) {
  final index = args.indexOf(key);
  if (index == -1) return null;
  if (index + 1 >= args.length) return null;
  return args[index + 1];
}
