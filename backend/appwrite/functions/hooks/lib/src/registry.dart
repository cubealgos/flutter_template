import 'package:hooks/src/paddle_hook.dart';
import 'package:hooks/src/webhook_hook.dart';

/// Every webhook the `hooks` Function receives. **To add one, append it
/// here**: a class implementing `WebhookHook` with its own path, secret and
/// signature check (see "Billing" in `backend/appwrite/README.md`).
final List<WebhookHook> hooks = <WebhookHook>[PaddleHook()];

/// The Appwrite API-key scopes the `hooks` Function needs: rows of the
/// billing tables, and nothing else. `FunctionSchema.scopes` for `hooks` must
/// be exactly this (`test/scopes_test.dart`); a hook that needs more must
/// say so here, so the widening is a visible, reviewed change.
const Set<String> requiredScopes = <String>{
  'tables.read',
  'tables.write',
  'collections.read',
  'collections.write',
  'documents.read',
  'documents.write',
};
