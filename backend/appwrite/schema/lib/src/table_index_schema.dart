/// An index on a table (see `package:appwrite_schema/src/table_schema.dart`).
class TableIndexSchema {
  /// Declares an index named [key] over [columns].
  const TableIndexSchema({
    required this.key,
    required this.columns,
    this.unique = false,
  });

  /// A unique index enforcing "at most one open row per key" over
  /// [openKeyColumn].
  ///
  /// Appwrite has no partial (filtered) unique index, so the pattern is a
  /// nullable, optional column that holds the key **while the row is open**
  /// and is set to null when it closes. A unique index treats nulls as
  /// distinct, so any number of closed rows coexist while a second open row
  /// with the same key is rejected. [openKeyColumn] must be declared
  /// `isRequired: false` on the table (the schema test checks this).
  ///
  /// Not `const` (it builds the column list); declare it with `final`, or
  /// spell the equivalent `const TableIndexSchema(key: '<col>_open_unique',
  /// columns: ['<col>'], unique: true)` inside a const schema.
  factory TableIndexSchema.oneOpenRowPerKey({required String openKeyColumn}) =>
      TableIndexSchema(
        key: '${openKeyColumn}_open_unique',
        columns: <String>[openKeyColumn],
        unique: true,
      );

  /// The index's key.
  final String key;

  /// The columns the index covers, in order.
  final List<String> columns;

  /// Whether the index enforces uniqueness.
  final bool unique;
}
