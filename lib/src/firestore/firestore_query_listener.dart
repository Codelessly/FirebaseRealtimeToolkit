import 'dart:async';

import 'package:firebase_realtime_toolkit/firebase_realtime_toolkit.dart';
import 'package:firebase_realtime_toolkit/src/firestore_proto/google/firestore/v1/firestore.pbgrpc.dart'
    as fs;
import 'package:firebase_realtime_toolkit/src/firestore_proto/google/firestore/v1/query.pb.dart'
    as query;
import 'package:firebase_realtime_toolkit/src/firestore_proto/google/firestore/v1/document.pb.dart'
    as doc;
import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:grpc/grpc.dart';
import 'package:protobuf/well_known_types/google/protobuf/struct.pbenum.dart'
    as struct;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as timestamp;
import 'package:protobuf/well_known_types/google/protobuf/wrappers.pb.dart'
    as wrappers;

/// Extension to FirestoreListenClient that adds collection query listening support.
class FirestoreQueryListener {
  FirestoreQueryListener({
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

  /// Listen to a collection with optional query filters.
  Stream<fs.ListenResponse> listenQuery({
    required String collectionPath,
    List<QueryFilter>? filters,
    List<QueryOrder>? orderBy,
    int? limit,
    int targetId = 1,
  }) async* {
    final controller = StreamController<fs.ListenResponse>();
    StreamController<fs.ListenRequest>? requestController;
    StreamSubscription<fs.ListenResponse>? responseSubscription;

    controller.onListen = () async {
      final token = await tokenProvider.getAccessToken();

      // Build structured query
      final structuredQuery = query.StructuredQuery(
        from: [
          query.StructuredQuery_CollectionSelector(
            collectionId: _getCollectionId(collectionPath),
          ),
        ],
      );

      // Add filters
      if (filters != null && filters.isNotEmpty) {
        final filterList = filters.map((f) => _buildFilter(f)).toList();
        if (filterList.length == 1) {
          structuredQuery.where = filterList.first;
        } else {
          structuredQuery.where = query.StructuredQuery_Filter(
            compositeFilter: query.StructuredQuery_CompositeFilter(
              op: query.StructuredQuery_CompositeFilter_Operator.AND,
              filters: filterList,
            ),
          );
        }
      }

      // Add order by
      if (orderBy != null && orderBy.isNotEmpty) {
        structuredQuery.orderBy.addAll(
          orderBy.map((o) {
            final order = query.StructuredQuery_Order(
              direction: o.descending
                  ? query.StructuredQuery_Direction.DESCENDING
                  : query.StructuredQuery_Direction.ASCENDING,
            );
            order.field_1 = query.StructuredQuery_FieldReference(fieldPath: o.field);
            return order;
          }),
        );
      }

      // Add limit
      if (limit != null) {
        structuredQuery.limit = wrappers.Int32Value(value: limit);
      }

      final parentPath = _getParentPath(collectionPath);
      final parent = parentPath.isEmpty
          ? '$_databasePath/documents'
          : '$_databasePath/documents/$parentPath';

      final request = fs.ListenRequest(
        database: _databasePath,
        addTarget: fs.Target(
          targetId: targetId,
          query: fs.Target_QueryTarget(
            parent: parent,
            structuredQuery: structuredQuery,
          ),
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

  query.StructuredQuery_Filter _buildFilter(QueryFilter filter) {
    final fieldFilter = query.StructuredQuery_FieldFilter(
      field_1: query.StructuredQuery_FieldReference(fieldPath: filter.field),
      op: _convertOperator(filter.operator),
      value: _convertValue(filter.value),
    );

    return query.StructuredQuery_Filter(
      fieldFilter: fieldFilter,
    );
  }

  query.StructuredQuery_FieldFilter_Operator _convertOperator(
      FilterOperator op) {
    switch (op) {
      case FilterOperator.equal:
        return query.StructuredQuery_FieldFilter_Operator.EQUAL;
      case FilterOperator.notEqual:
        return query.StructuredQuery_FieldFilter_Operator.NOT_EQUAL;
      case FilterOperator.lessThan:
        return query.StructuredQuery_FieldFilter_Operator.LESS_THAN;
      case FilterOperator.lessThanOrEqual:
        return query.StructuredQuery_FieldFilter_Operator.LESS_THAN_OR_EQUAL;
      case FilterOperator.greaterThan:
        return query.StructuredQuery_FieldFilter_Operator.GREATER_THAN;
      case FilterOperator.greaterThanOrEqual:
        return query
            .StructuredQuery_FieldFilter_Operator.GREATER_THAN_OR_EQUAL;
      case FilterOperator.arrayContains:
        return query.StructuredQuery_FieldFilter_Operator.ARRAY_CONTAINS;
      case FilterOperator.inArray:
        return query.StructuredQuery_FieldFilter_Operator.IN;
      case FilterOperator.arrayContainsAny:
        return query.StructuredQuery_FieldFilter_Operator.ARRAY_CONTAINS_ANY;
      case FilterOperator.notIn:
        return query.StructuredQuery_FieldFilter_Operator.NOT_IN;
    }
  }

  doc.Value _convertValue(dynamic value) {
    if (value == null) {
      return doc.Value(nullValue: struct.NullValue.NULL_VALUE);
    } else if (value is bool) {
      return doc.Value(booleanValue: value);
    } else if (value is int) {
      return doc.Value(integerValue: fixnum.Int64(value));
    } else if (value is double) {
      return doc.Value(doubleValue: value);
    } else if (value is String) {
      return doc.Value(stringValue: value);
    } else if (value is DateTime) {
      return doc.Value(
        timestampValue: timestamp.Timestamp(
          seconds: fixnum.Int64(value.millisecondsSinceEpoch ~/ 1000),
          nanos: (value.millisecondsSinceEpoch % 1000) * 1000000,
        ),
      );
    }
    // Default to string representation
    return doc.Value(stringValue: value.toString());
  }

  String _getCollectionId(String collectionPath) {
    final parts = collectionPath.split('/');
    return parts.last;
  }

  String _getParentPath(String collectionPath) {
    final parts = collectionPath.split('/');
    if (parts.length == 1) {
      return '';
    }
    return parts.sublist(0, parts.length - 1).join('/');
  }

  Future<void> close() async {
    await _channel.shutdown();
  }
}

/// Query filter for Firestore queries.
class QueryFilter {
  const QueryFilter({
    required this.field,
    required this.operator,
    required this.value,
  });

  final String field;
  final FilterOperator operator;
  final dynamic value;
}

/// Query ordering for Firestore queries.
class QueryOrder {
  const QueryOrder({
    required this.field,
    this.descending = false,
  });

  final String field;
  final bool descending;
}

/// Filter operators for Firestore queries.
enum FilterOperator {
  equal,
  notEqual,
  lessThan,
  lessThanOrEqual,
  greaterThan,
  greaterThanOrEqual,
  arrayContains,
  inArray,
  arrayContainsAny,
  notIn,
}
