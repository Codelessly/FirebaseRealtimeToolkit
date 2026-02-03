import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart' as auth;

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('Usage: firebase_webapp <service-account.json> <projectId>');
    exit(64);
  }
  final serviceAccount = args[0];
  final projectId = args[1];

  final jsonKey = await File(serviceAccount).readAsString();
  final credentials = auth.ServiceAccountCredentials.fromJson(jsonKey);
  final client = await auth.clientViaServiceAccount(
    credentials,
    const [
      'https://www.googleapis.com/auth/firebase',
      'https://www.googleapis.com/auth/cloud-platform',
    ],
  );

  final listUrl = Uri.parse(
    'https://firebase.googleapis.com/v1beta1/projects/$projectId/webApps',
  );
  final listResp = await client.get(listUrl);
  stdout.writeln('LIST ${listResp.statusCode} ${listResp.body}');

  String? appId;
  if (listResp.statusCode == 200) {
    final decoded = jsonDecode(listResp.body) as Map<String, dynamic>;
    final apps = (decoded['apps'] as List<dynamic>?) ?? [];
    if (apps.isNotEmpty) {
      final first = apps.first as Map<String, dynamic>;
      final name = first['name'] as String?;
      if (name != null) {
        appId = name.split('/').last;
      }
    }
  }

  if (appId == null) {
    final createUrl = Uri.parse(
      'https://firebase.googleapis.com/v1beta1/projects/$projectId/webApps',
    );
    final createResp = await client.post(
      createUrl,
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'displayName': 'Storyboard Web'}),
    );
    stdout.writeln('CREATE ${createResp.statusCode} ${createResp.body}');
    if (createResp.statusCode >= 200 && createResp.statusCode < 300) {
      final decoded = jsonDecode(createResp.body) as Map<String, dynamic>;
      final opName = decoded['name'] as String?;
      if (opName != null) {
        final opUrl =
            Uri.parse('https://firebase.googleapis.com/v1beta1/$opName');
        for (var i = 0; i < 15; i++) {
          final opResp = await client.get(opUrl);
          if (opResp.statusCode == 200) {
            final opDecoded = jsonDecode(opResp.body) as Map<String, dynamic>;
            if (opDecoded['done'] == true) {
              final response = opDecoded['response'] as Map<String, dynamic>?;
              final name = response?['name'] as String?;
              if (name != null) {
                appId = name.split('/').last;
              }
              break;
            }
          }
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
    }
  }

  if (appId == null) {
    stderr.writeln('Unable to determine web app id');
    exit(1);
  }

  final configUrl = Uri.parse(
    'https://firebase.googleapis.com/v1beta1/projects/$projectId/webApps/$appId/config',
  );
  final configResp = await client.get(configUrl);
  stdout.writeln('CONFIG ${configResp.statusCode} ${configResp.body}');

  client.close();
}
