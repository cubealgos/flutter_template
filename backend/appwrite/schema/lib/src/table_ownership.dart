import 'package:appwrite_schema/src/owned_file_ref.dart';

/// Declares that a table (see
/// `package:appwrite_schema/src/table_schema.dart`) is user-owned: its rows
/// carry the owning user's ID, and `delete_account` removes every row (and
/// any file it references) that belongs to the calling user.
class TableOwnership {
  /// Creates an ownership declaration keyed on [userIdColumn].
  const TableOwnership({required this.userIdColumn, this.fileRefs = const []});

  /// The column holding the owning user's Appwrite user ID.
  final String userIdColumn;

  /// File references on this table to delete alongside each owned row.
  final List<OwnedFileRef> fileRefs;
}
