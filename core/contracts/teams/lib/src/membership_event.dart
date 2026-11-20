import 'package:teams/src/invitation.dart';
import 'package:teams/src/membership_event_type.dart';

/// One entry in a team's membership history: who did what to whom, when.
///
/// Carries the people's user IDs **and an email snapshot**, so the record
/// stays readable, and means something, after the person's membership (or
/// account) is gone. Events are append-only: nothing in `TeamService`
/// edits or deletes one.
class MembershipEvent {
  /// Creates an event.
  const MembershipEvent({
    required this.id,
    required this.teamId,
    required this.type,
    required this.actorUserId,
    required this.at,
    this.actorEmail,
    this.subjectUserId,
    this.subjectEmail,
    this.role,
    this.previousRole,
  });

  /// The event recording that [invitation] lapsed unaccepted at [at], by the
  /// [systemActorId] (no person caused it).
  MembershipEvent.invitationExpired({
    required String id,
    required Invitation invitation,
    required DateTime at,
  }) : this(
         id: id,
         teamId: invitation.teamId,
         type: MembershipEventType.expired,
         actorUserId: systemActorId,
         subjectEmail: invitation.email,
         role: invitation.role,
         at: at,
       );

  /// What replaces an email snapshot once it is past its retention period
  /// (see `TeamEngine.redactEmailsOlderThan`): a neutral marker an app shows
  /// as "former member". It is not an email address, and the user IDs stay.
  static const String formerMember = 'former member';

  /// The actor of an event no person caused (an invitation expiring).
  static const String systemActorId = 'system';

  /// The event's ID.
  final String id;

  /// The team it happened in.
  final String teamId;

  /// What happened.
  final MembershipEventType type;

  /// The user who did it (`TeamEngine.systemActorId` for an expiry).
  final String actorUserId;

  /// The actor's email at the time, if known.
  final String? actorEmail;

  /// The user it was done to, when there is one yet (an invitee has no
  /// user ID until they accept).
  final String? subjectUserId;

  /// The subject's email at the time.
  final String? subjectEmail;

  /// The role involved: granted, or the new role.
  final String? role;

  /// The role before a `MembershipEventType.roleChanged` or the
  /// transferring owner's role before a transfer.
  final String? previousRole;

  /// When it happened.
  final DateTime at;

  /// A copy whose email snapshots (those present) are replaced by [marker].
  /// Everything else, the user IDs included, is kept.
  MembershipEvent withEmailsReplacedBy(String marker) => MembershipEvent(
    id: id,
    teamId: teamId,
    type: type,
    actorUserId: actorUserId,
    at: at,
    actorEmail: actorEmail == null ? null : marker,
    subjectUserId: subjectUserId,
    subjectEmail: subjectEmail == null ? null : marker,
    role: role,
    previousRole: previousRole,
  );

  @override
  String toString() =>
      'MembershipEvent($type, team: $teamId, actor: $actorUserId, at: $at)';
}
