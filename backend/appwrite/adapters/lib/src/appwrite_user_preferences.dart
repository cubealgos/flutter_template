import 'package:appwrite/appwrite.dart';
import 'package:appwrite_adapters/src/account_gateway.dart';
import 'package:appwrite_adapters/src/appwrite_account_gateway.dart';
import 'package:appwrite_adapters/src/appwrite_data_error_mapping.dart';
import 'package:data/data.dart';
import 'package:meta/meta.dart';

/// The [UserPreferences] implementation backed by Appwrite's `Account`
/// service (via [AccountGateway]'s `getPrefs`/`updatePrefs`).
///
/// Appwrite's `Account.updatePrefs` always *replaces* the whole
/// preferences object — there is no server-side merge. [update] provides
/// `UserPreferences.update`'s documented merge semantics on top by reading
/// the current value first, merging [update]'s `changes` locally, and
/// writing the merged result back — not race-free against a concurrent
/// writer on the same account (this template has none; the consent choice
/// and onboarding checklist are only ever written by the signed-in user's
/// own device), but never silently drops a key nothing this call touched.
class AppwriteUserPreferences implements UserPreferences {
  /// Creates a service backed by [client].
  AppwriteUserPreferences(Client client)
    : _gateway = AppwriteAccountGateway(client);

  /// Creates a service against a given [gateway] directly — for tests,
  /// matching `AppwriteAuthService.withGateway`.
  @visibleForTesting
  AppwriteUserPreferences.withGateway(AccountGateway gateway)
    : _gateway = gateway;

  final AccountGateway _gateway;

  @override
  Future<Map<String, dynamic>> getAll() async {
    try {
      final prefs = await _gateway.getPrefs();

      return Map<String, dynamic>.of(prefs.data);
    } on AppwriteException catch (e) {
      throw mapAppwriteDataError(e);
    }
  }

  @override
  Future<void> update(Map<String, dynamic> changes) async {
    try {
      final current = await _gateway.getPrefs();
      final merged = Map<String, dynamic>.of(current.data);
      for (final entry in changes.entries) {
        if (entry.value == null) {
          merged.remove(entry.key);
        } else {
          merged[entry.key] = entry.value;
        }
      }
      await _gateway.updatePrefs(merged);
    } on AppwriteException catch (e) {
      throw mapAppwriteDataError(e);
    }
  }
}
