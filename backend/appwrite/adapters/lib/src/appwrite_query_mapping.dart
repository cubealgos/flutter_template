import 'package:appwrite/appwrite.dart';
import 'package:data/data.dart';

/// Maps a backend-agnostic [DataQuery] to the `List<String>` shape
/// `TablesDB.listRows`'s own `queries` parameter expects.
///
/// A standalone, pure function (no `Client` needed) so it can be unit
/// tested directly, without a live Appwrite instance or a fake gateway.
List<String> buildAppwriteQueries(DataQuery query) {
  final queries = <String>[
    for (final filter in query.filters) _buildFilterQuery(filter),
  ];

  final orderByField = query.orderByField;
  if (orderByField != null) {
    queries.add(
      query.orderDescending
          ? Query.orderDesc(orderByField)
          : Query.orderAsc(orderByField),
    );
  }

  final limit = query.limit;
  if (limit != null) queries.add(Query.limit(limit));

  return queries;
}

String _buildFilterQuery(DataFilter filter) => switch (filter) {
  EqualsFilter(:final field, :final value) => Query.equal(field, value),
};
