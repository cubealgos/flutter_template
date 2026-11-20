import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mvc/mvc.dart';
import 'package:teams/teams.dart';

part 'teams_model.freezed.dart';

/// `TeamsView`'s view model: the user's teams, which one is active, the
/// invitations waiting for them, and whether a call is running or failed.
@freezed
abstract class TeamsModel with _$TeamsModel implements ViewModel {
  /// Creates the model.
  const factory TeamsModel({
    /// The active team's ID, if it is one of [teams].
    String? activeTeamId,

    /// The teams the user belongs to.
    @Default(<Team>[]) List<Team> teams,

    /// Pending invitations addressed to the user's email.
    @Default(<Invitation>[]) List<Invitation> invitations,

    /// Whether the lists are still loading.
    @Default(true) bool loading,

    /// Whether a create/accept/switch call is running.
    @Default(false) bool busy,

    /// Whether the last call failed.
    @Default(false) bool failed,
  }) = _TeamsModel;
}
