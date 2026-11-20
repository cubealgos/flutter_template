/// The default `size` a [ColumnSchema.type] of [ColumnType.varchar] gets
/// when [ColumnSchema.size] isn't set explicitly — long enough for an
/// Appwrite ID (typically ≤36 chars) with headroom, short enough to stay
/// well under MariaDB's ~767-byte indexable-prefix limit even for a
/// multi-column composite index.
const int defaultVarcharColumnSize = 255;

/// One column on a table (see `package:appwrite_schema/src/table_schema.dart`).
class ColumnSchema {
  /// Declares a column named [key] of [type].
  const ColumnSchema({
    required this.key,
    required this.type,
    this.isRequired = true,
    this.isArray = false,
    this.size = defaultVarcharColumnSize,
  });

  /// The column's key (attribute name).
  final String key;

  /// The column's Appwrite type.
  final ColumnType type;

  /// Whether rows must supply this column.
  final bool isRequired;

  /// Whether this column holds an array of [type].
  final bool isArray;

  /// The column's maximum length. Only meaningful when [type] is
  /// [ColumnType.varchar] — ignored otherwise.
  final int size;
}

/// The column types the provisioner knows how to create.
///
/// Deliberately a small, closed set — just enough for the template's own
/// example table. An app growing its schema adds the Appwrite column types
/// it actually needs (numbers, enums, relationships, …) directly against
/// `package:dart_appwrite`'s `TablesDB` service; this enum only covers what
/// `bin/provision.dart` itself creates on a clean instance.
enum ColumnType {
  /// An unbounded text column (`TablesDB.createTextColumn`). **Cannot be
  /// indexed**: MariaDB (Appwrite's database) caps an index's indexable
  /// prefix at ~767 bytes, which an unbounded text column always exceeds —
  /// creating a unique/key index on one fails with `column_index_invalid` (found by
  /// hand against a real Appwrite 2.2.0 + MariaDB instance while
  /// building this schema). Use [varchar] for any column a
  /// `TableIndexSchema` references.
  text,

  /// A bounded string column (`TablesDB.createVarcharColumn`), sized by
  /// [ColumnSchema.size]. Use this, not [text], for any column that needs
  /// an index — see [text]'s dartdoc for why.
  varchar,

  /// A boolean column (`TablesDB.createBooleanColumn`).
  boolean,

  /// An ISO-8601 datetime column (`TablesDB.createDatetimeColumn`).
  datetime,
}
