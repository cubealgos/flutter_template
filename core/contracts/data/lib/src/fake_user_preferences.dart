import 'package:data/src/data_error.dart';
import 'package:data/src/user_preferences.dart';

/// An in-memory [UserPreferences] for screens and tests.
///
/// Set [authenticated] to false to simulate a signed-out user, matching
/// `FakeDocumentRepository`'s convention.
class FakeUserPreferences implements UserPreferences {
  /// Creates an empty in-memory preference store.
  FakeUserPreferences({this.authenticated = true});

  /// Whether calls should succeed as a signed-in user. Flip to false to
  /// make every method throw [DataUnauthenticatedError].
  bool authenticated;

  final Map<String, dynamic> _prefs = <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> getAll() async {
    _requireAuthenticated();

    return Map<String, dynamic>.of(_prefs);
  }

  @override
  Future<void> update(Map<String, dynamic> changes) async {
    _requireAuthenticated();
    for (final entry in changes.entries) {
      if (entry.value == null) {
        _prefs.remove(entry.key);
      } else {
        _prefs[entry.key] = entry.value;
      }
    }
  }

  void _requireAuthenticated() {
    if (!authenticated) {
      throw const DataUnauthenticatedError('No current user.');
    }
  }
}
