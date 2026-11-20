import 'package:app/app/preference_keys.dart';
import 'package:data/data.dart';
import 'package:injectable/injectable.dart';

/// Which team the user is working in: read and written through
/// [UserPreferences], so it survives a restart and follows the account to
/// another device.
///
/// It stores only an ID. Whether the user still belongs to that team is the
/// caller's question to answer from `TeamService.listTeams`; a stale ID
/// means nothing here.
@lazySingleton
class ActiveTeamService {
  /// Creates the service over `preferences`.
  ActiveTeamService(this._preferences);

  final UserPreferences _preferences;

  /// The stored active team ID, or null if none was chosen.
  Future<String?> activeTeamId() async {
    final value = (await _preferences.getAll())[activeTeamIdPreferenceKey];

    return value is String ? value : null;
  }

  /// Makes [teamId] the active team.
  Future<void> switchTo(String teamId) =>
      _preferences.update(<String, dynamic>{activeTeamIdPreferenceKey: teamId});
}
