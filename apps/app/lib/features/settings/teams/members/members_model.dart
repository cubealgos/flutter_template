import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mvc/mvc.dart';
import 'package:teams/teams.dart';

part 'members_model.freezed.dart';

/// `MembersView`'s view model: the active team, its members, its pending
/// invitations, and what the current user may do.
@freezed
abstract class MembersModel with _$MembersModel implements ViewModel {
  /// Creates the model.
  const factory MembersModel({
    /// The active team, or null if there is none (or it can't be read).
    Team? team,

    /// The current user's role in [team], or null while unknown.
    String? myRole,

    /// The team's members.
    @Default(<Membership>[]) List<Membership> members,

    /// The team's invitations still waiting for an answer. Empty unless the
    /// current user is the owner or an admin, who alone may list them.
    @Default(<Invitation>[]) List<Invitation> pendingInvitations,

    /// Whether the lists are still loading.
    @Default(true) bool loading,

    /// Whether an invite/revoke call is running.
    @Default(false) bool busy,

    /// Whether the last call failed.
    @Default(false) bool failed,
  }) = _MembersModel;

  const MembersModel._();

  /// Whether the current user may invite and revoke: the owner and admins.
  bool get canManage => myRole == TeamRoles.owner || myRole == TeamRoles.admin;

  /// Whether the current user may leave: everyone but the owner (who must
  /// transfer ownership first).
  bool get canLeave => myRole != null && myRole != TeamRoles.owner;
}
