import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart' as auth;

void main(List<String> args) async {
  final serviceAccount = _argValue(args, '--service-account');
  final projectId = _argValue(args, '--project');
  final documentPath = _argValue(args, '--document');
  final databaseId = _argValue(args, '--database') ?? '(default)';
  final field = _argValue(args, '--field') ?? 'status';
  final value = _argValue(args, '--value') ?? 'updated';

  if (serviceAccount == null || projectId == null || documentPath == null) {
    stderr.writeln(
        'Usage: firestore_write --service-account <path> --project <id> --document <collection/doc> [--database (default)] [--field status] [--value updated]');
    exit(64);
  }

  final jsonKey = await File(serviceAccount).readAsString();
  final credentials = auth.ServiceAccountCredentials.fromJson(jsonKey);
  final client = await auth.clientViaServiceAccount(
    credentials,
    const [
      'https://www.googleapis.com/auth/cloud-platform',
      'https://www.googleapis.com/auth/datastore',
    ],
  );

  final normalizedPath =
      documentPath.startsWith('/') ? documentPath.substring(1) : documentPath;

  final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/$databaseId/documents/$normalizedPath');

  final body = json.encode({
    'fields': {
      field: {'stringValue': value}
    }
  });

  final response = await client.patch(
    url,
    headers: {
      'content-type': 'application/json',
    },
    body: body,
  );

  if (response.statusCode >= 200 && response.statusCode < 300) {
    stdout.writeln('Write ok: ${response.statusCode}');
  } else {
    stderr.writeln('Write failed: ${response.statusCode} ${response.body}');
    exit(1);
  }

  client.close();
}

String? _argValue(List<String> args, String key) {
  final index = args.indexOf(key);
  if (index == -1) return null;
  if (index + 1 >= args.length) return null;
  return args[index + 1];
}
