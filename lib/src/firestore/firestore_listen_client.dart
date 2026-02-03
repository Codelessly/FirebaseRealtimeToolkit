import 'dart:async';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:grpc/grpc.dart';

import '../firestore_proto/google/firestore/v1/firestore.pbgrpc.dart' as fs;

abstract class AccessTokenProvider {
  Future<auth.AccessToken> getAccessToken();
}

class ServiceAccountTokenProvider implements AccessTokenProvider {
  ServiceAccountTokenProvider(this.serviceAccountJsonPath,
      {this.scopes = fs.FirestoreClient.oauthScopes});

  final String serviceAccountJsonPath;
  final List<String> scopes;

  @override
  Future<auth.AccessToken> getAccessToken() async {
    final json = await File(serviceAccountJsonPath).readAsString();
    final credentials = auth.ServiceAccountCredentials.fromJson(json);
    final client = await auth.clientViaServiceAccount(credentials, scopes);
    final token = client.credentials.accessToken;
    client.close();
    return token;
  }
}

class FirestoreListenClient {
  FirestoreListenClient({
    required this.projectId,
    this.databaseId = '(default)',
    required this.tokenProvider,
    ClientChannel? channel,
  }) : _channel = channel ??
            ClientChannel(
              fs.FirestoreClient.defaultHost,
              port: 443,
              options: const ChannelOptions(
                credentials: ChannelCredentials.secure(),
              ),
            );

  final String projectId;
  final String databaseId;
  final AccessTokenProvider tokenProvider;
  final ClientChannel _channel;

  fs.FirestoreClient get _client => fs.FirestoreClient(_channel);

  String get _databasePath => 'projects/$projectId/databases/$databaseId';

  Stream<fs.ListenResponse> listenDocument(
    String documentPath, {
    int targetId = 1,
  }) async* {
    final controller = StreamController<fs.ListenResponse>();
    StreamController<fs.ListenRequest>? requestController;
    StreamSubscription<fs.ListenResponse>? responseSubscription;

    controller.onListen = () async {
      final docName =
          '$_databasePath/documents/${_normalizePath(documentPath)}';
      final token = await tokenProvider.getAccessToken();

      final request = fs.ListenRequest(
        database: _databasePath,
        addTarget: fs.Target(
          targetId: targetId,
          documents: fs.Target_DocumentsTarget(documents: [docName]),
        ),
      );

      final callOptions = CallOptions(
        metadata: {
          'authorization': 'Bearer ${token.data}',
          'google-cloud-resource-prefix': _databasePath,
          'x-goog-request-params': 'database=$_databasePath',
        },
      );

      requestController = StreamController<fs.ListenRequest>();
      final responseStream =
          _client.listen(requestController!.stream, options: callOptions);

      responseSubscription = responseStream.listen(
        controller.add,
        onError: controller.addError,
        onDone: () {
          if (!controller.isClosed) {
            controller.close();
          }
        },
      );

      requestController!.add(request);
    };

    controller.onCancel = () async {
      await responseSubscription?.cancel();
      await requestController?.close();
    };

    yield* controller.stream;
  }

  Future<void> close() async {
    await _channel.shutdown();
  }

  String _normalizePath(String path) {
    if (path.startsWith('/')) return path.substring(1);
    return path;
  }
}
