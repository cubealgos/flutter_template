/// Pure-Dart domain models shared between the app and the Appwrite
/// Functions under `backend/appwrite/functions/`.
///
/// This package has no Flutter dependency on purpose: `backend/appwrite/tool/bin/deploy.dart`
/// bundles it as a path dependency (`./vendor/domain`) into every function
/// deployment, where only a plain Dart AOT runtime is available server-side
/// — see `backend/appwrite/README.md`.
library;

export 'src/account_deletion_result.dart';
export 'src/user_profile.dart';
