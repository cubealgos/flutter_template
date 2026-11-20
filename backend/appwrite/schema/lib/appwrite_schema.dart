/// The template's declarative Appwrite backend schema: the database, its
/// tables and columns, storage buckets, and Functions.
///
/// A standalone pure-Dart package (no dependencies at all) so it can be
/// depended on by both `appwrite_tool` (`bin/provision.dart` reads it to
/// create/update resources idempotently, `bin/deploy.dart` reads it to find
/// a Function's deploy metadata) and by `backend/appwrite/functions/api`
/// — without the function's deployed bundle also vendoring `appwrite_tool`'s
/// own provisioning/deployment tooling dependencies (`archive`, `http`,
/// `yaml`) that it has no use for.
///
/// Ownership declarations (`TableOwnership`) are what let
/// `backend/appwrite/functions/api`'s `delete_account` action know which rows and files belong to
/// the calling user without hard-coding table names into the function
/// itself — see
/// `backend/appwrite/functions/api/lib/src/actions/delete_account/deletion_service.dart`.
///
/// Split into one file per declared type under `src/` (each file name
/// matches the type it declares, per this workspace's
/// `prefer_match_file_name` lint) — this file just re-exports all of them.
library;

export 'src/api_key_schema.dart';
export 'src/appwrite_schema.dart';
export 'src/bucket_schema.dart';
export 'src/column_schema.dart';
export 'src/function_schema.dart';
export 'src/mail_provider_schema.dart';
export 'src/native_team_role.dart';
export 'src/owned_file_ref.dart';
export 'src/seed_row.dart';
export 'src/site_schema.dart';
export 'src/table_index_schema.dart';
export 'src/table_ownership.dart';
export 'src/table_schema.dart';
