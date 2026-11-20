import 'package:data/src/data_filter.dart';

/// A backend-agnostic query shape for `DocumentRepository.query`.
///
/// Deliberately small: equality filters, one sort field, and a limit —
/// "what an app needs to start, not a query language" (per the issue).
/// An app that outgrows this extends [DataFilter] or adds fields here
/// after cloning, rather than this package trying to model every
/// TablesDB/Firestore/whatever query capability up front.
class DataQuery {
  /// Creates a query. An empty [filters] list with no [orderByField] or
  /// [limit] returns every document in the collection (up to whatever
  /// page size the backend itself defaults to).
  const DataQuery({
    this.orderByField,
    this.limit,
    this.filters = const <DataFilter>[],
    this.orderDescending = false,
  });

  /// Equality filters, combined with AND.
  final List<DataFilter> filters;

  /// The field to sort by, or null for the backend's default order.
  final String? orderByField;

  /// Whether to sort descending. Ignored if [orderByField] is null.
  final bool orderDescending;

  /// The maximum number of documents to return, or null for the backend's
  /// default page size.
  final int? limit;
}
