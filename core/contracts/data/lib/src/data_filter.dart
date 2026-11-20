/// One filter condition in a `DataQuery`.
///
/// A sealed class with a single variant today ([EqualsFilter]) rather than
/// an open-ended query language — see `DataQuery`'s dartdoc for why. A
/// cloned app adds a variant here (e.g. a range filter) when it actually
/// needs one; the `switch` in
/// `FakeDocumentRepository`/`AppwriteDocumentRepository`'s query mapping
/// then fails to compile until every implementation handles it, so nothing
/// is silently ignored.
sealed class DataFilter {
  /// Creates a filter on [field].
  const DataFilter(this.field);

  /// The document field this filter applies to.
  final String field;
}

/// Matches documents where [field] equals [value].
final class EqualsFilter extends DataFilter {
  /// Creates an equality filter.
  const EqualsFilter(super.field, this.value);

  /// The value [field] must equal.
  final Object? value;
}
