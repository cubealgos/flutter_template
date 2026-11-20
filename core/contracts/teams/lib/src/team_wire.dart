import 'package:teams/src/invitation.dart';
import 'package:teams/src/invitation_status.dart';
import 'package:teams/src/membership.dart';
import 'package:teams/src/membership_event.dart';
import 'package:teams/src/membership_event_type.dart';
import 'package:teams/src/team.dart';
import 'package:teams/src/team_error.dart';

/// The JSON shape `backend/appwrite/functions/team_admin` and
/// `AppwriteTeamService` speak to each other, so the two ends can't drift:
/// one encoder and decoder per model, and the mapping between a
/// [TeamError] and its wire code and HTTP status.
///
/// A request is `{"action": <TeamWire action>, ...arguments}`; a success is
/// `{"result": ...}`; a failure is `{"error": {"code": ..., "message": ...}}`
/// with the status [statusFor] gives.
abstract final class TeamWire {
  static const int _unauthenticated = 401;
  static const int _forbidden = 403;
  static const int _notFound = 404;
  static const int _conflict = 409;
  static const int _unprocessable = 422;
  static const int _serverError = 500;

  /// Encodes [team].
  static Map<String, dynamic> encodeTeam(Team team) => <String, dynamic>{
    'id': team.id,
    'name': team.name,
  };

  /// Decodes a team encoded by [encodeTeam].
  static Team decodeTeam(Map<String, dynamic> json) =>
      Team(id: json['id'] as String, name: json['name'] as String);

  /// Encodes [membership].
  static Map<String, dynamic> encodeMembership(Membership membership) =>
      <String, dynamic>{
        'teamId': membership.teamId,
        'userId': membership.userId,
        'email': membership.email,
        'role': membership.role,
        'joinedAt': _time(membership.joinedAt),
        'membershipId': membership.membershipId,
      };

  /// Decodes a membership encoded by [encodeMembership].
  static Membership decodeMembership(Map<String, dynamic> json) => Membership(
    teamId: json['teamId'] as String,
    userId: json['userId'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    joinedAt: DateTime.parse(json['joinedAt'] as String),
    membershipId: json['membershipId'] as String?,
  );

  /// Encodes [invitation].
  static Map<String, dynamic> encodeInvitation(Invitation invitation) =>
      <String, dynamic>{
        'id': invitation.id,
        'teamId': invitation.teamId,
        'teamName': invitation.teamName,
        'email': invitation.email,
        'role': invitation.role,
        'invitedBy': invitation.invitedBy,
        'createdAt': _time(invitation.createdAt),
        'expiresAt': _time(invitation.expiresAt),
        'status': invitation.status.name,
      };

  /// Decodes an invitation encoded by [encodeInvitation].
  static Invitation decodeInvitation(Map<String, dynamic> json) => Invitation(
    id: json['id'] as String,
    teamId: json['teamId'] as String,
    teamName: json['teamName'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    invitedBy: json['invitedBy'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    status: InvitationStatus.values.byName(json['status'] as String),
  );

  /// Encodes [event].
  static Map<String, dynamic> encodeEvent(MembershipEvent event) =>
      <String, dynamic>{
        'id': event.id,
        'teamId': event.teamId,
        'type': event.type.name,
        'actorUserId': event.actorUserId,
        'actorEmail': event.actorEmail,
        'subjectUserId': event.subjectUserId,
        'subjectEmail': event.subjectEmail,
        'role': event.role,
        'previousRole': event.previousRole,
        'at': _time(event.at),
      };

  /// Decodes an event encoded by [encodeEvent].
  static MembershipEvent decodeEvent(Map<String, dynamic> json) =>
      MembershipEvent(
        id: json['id'] as String,
        teamId: json['teamId'] as String,
        type: MembershipEventType.values.byName(json['type'] as String),
        actorUserId: json['actorUserId'] as String,
        actorEmail: json['actorEmail'] as String?,
        subjectUserId: json['subjectUserId'] as String?,
        subjectEmail: json['subjectEmail'] as String?,
        role: json['role'] as String?,
        previousRole: json['previousRole'] as String?,
        at: DateTime.parse(json['at'] as String),
      );

  /// The wire code of [error].
  static String codeFor(TeamError error) => switch (error) {
    TeamNotFoundError() => 'not_found',
    TeamUnauthenticatedError() => 'unauthenticated',
    TeamPermissionError() => 'permission',
    TeamInvariantError() => 'invariant',
    TeamInvitationError() => 'invitation',
    TeamNetworkError() || TeamUnknownError() => 'unknown',
  };

  /// The HTTP status a Function responds with for [error].
  static int statusFor(TeamError error) => switch (error) {
    TeamUnauthenticatedError() => _unauthenticated,
    TeamPermissionError() => _forbidden,
    TeamNotFoundError() => _notFound,
    TeamInvitationError() => _conflict,
    TeamInvariantError() => _unprocessable,
    TeamNetworkError() || TeamUnknownError() => _serverError,
  };

  /// The error a client rebuilds from a wire [code] and [message].
  static TeamError errorFrom(String code, String message) => switch (code) {
    'not_found' => TeamNotFoundError(message),
    'unauthenticated' => TeamUnauthenticatedError(message),
    'permission' => TeamPermissionError(message),
    'invariant' => TeamInvariantError(message),
    'invitation' => TeamInvitationError(message),
    _ => TeamUnknownError(message),
  };

  /// The failure body for [error].
  static Map<String, dynamic> encodeError(TeamError error) => <String, dynamic>{
    'error': <String, dynamic>{
      'code': codeFor(error),
      'message': error.message,
    },
  };

  static String _time(DateTime time) => time.toUtc().toIso8601String();
}
