import 'dart:async';
import 'dart:io';

import 'package:firebase_realtime_toolkit/firebase_realtime_toolkit.dart';

void main(List<String> args) async {
  final baseUrl = _argValue(args, '--base') ??
      'https://autostoryboardapp-default-rtdb.firebaseio.com/';
  final path = _argValue(args, '--path') ?? '/';
  final auth = _argValue(args, '--auth');
  final durationSeconds =
      int.tryParse(_argValue(args, '--duration') ?? '0') ?? 0;

  final client = RtdbSseClient(Uri.parse(baseUrl));

  stdout.writeln('Connecting to $baseUrl path: $path');
  if (auth != null) {
    stdout.writeln('Auth token provided.');
  }

  final sub = client
      .listen(path, authToken: auth)
      .listen((event) => stdout.writeln('[${event.event}] ${event.rawData}'));

  if (durationSeconds > 0) {
    await Future.delayed(Duration(seconds: durationSeconds));
    await sub.cancel();
  }
}

String? _argValue(List<String> args, String key) {
  final index = args.indexOf(key);
  if (index == -1) return null;
  if (index + 1 >= args.length) return null;
  return args[index + 1];
}
