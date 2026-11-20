import 'package:teams/src/invitation.dart';
import 'package:teams/src/invitation_status.dart';
import 'package:teams/src/membership.dart';
import 'package:teams/src/membership_event.dart';
import 'package:teams/src/membership_event_type.dart';
import 'package:teams/src/team.dart';
import 'package:teams/src/team_actor.dart';
import 'package:teams/src/team_error.dart';
import 'package:teams/src/team_roles.dart';
import 'package:teams/src/team_store.dart';

/// The one implementation of the team rules, over a [TeamStore].
///
/// `FakeTeamService` runs it on `InMemoryTeamStore`; the `team_admin`
/// Appwrite Function runs the same class on Appwrite Teams and tables. That
/// is the point: the fake and the real backend cannot disagree about who may
/// do what.
///
/// **The rules.** The owner can do everything. An admin can invite, revoke,
/// change roles of and remove members who are neither admin nor owner. A
/// member can list the team and leave it. The owner can't leave or be
/// removed, and no role change or invitation can create an owner: only
/// [transferOwnership] moves the role, so a team has exactly one owner
/// whenever a call returns. Every non-owner member sees a team they don't
/// belong to as [TeamNotFoundError].
///
/// **Atomicity.** [TeamStore] has no transaction (Appwrite Teams has none
/// across memberships), so [transferOwnership] records its event, promotes
/// the new owner and only then demotes the old one: a failure in between
/// leaves two owners, never none. The next mutating call on that team
/// repairs it from the recorded event (see `_heal`). Two *concurrent*
/// conflicting calls by the same owner are not serialised.
class TeamEngine {
  /// Creates an engine over [store].
  ///
  /// [assignableRoles] is every role `invite`/`changeRole` may grant (never
  /// the owner role); an app adds its own. [clock] and [newId] are injected
  /// so tests and Functions control time and IDs.
  TeamEngine({
    required this.store,
    DateTime Function()? clock,
    String Function()? newId,
    this.invitationLifetime = const Duration(days: 7),
    this.assignableRoles = const <String>{TeamRoles.admin, TeamRoles.member},
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? _SequentialIds().next;

  /// The actor recorded for an event no person caused (an invitation
  /// expiring).
  static const String systemActorId = MembershipEvent.systemActorId;

  /// Where the state lives.
  final TeamStore store;

  /// How long an invitation stays acceptable.
  final Duration invitationLifetime;

  /// The roles that may be granted (the owner role never is).
  final Set<String> assignableRoles;

  final DateTime Function() _clock;
  final String Function() _newId;

  /// Creates a team; [actor] becomes its owner.
  Future<Team> createTeam(TeamActor actor, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const TeamInvariantError('A team needs a name.');
    }
    final team = Team(id: _newId(), name: trimmed);
    await store.saveTeam(team);
    await store.saveMembership(
      Membership(
        teamId: team.id,
        userId: actor.userId,
        email: _normalise(actor.email),
        role: TeamRoles.owner,
        joinedAt: _clock(),
      ),
    );
    await _record(
      MembershipEventType.teamCreated,
      team.id,
      actor,
      _Detail(subject: actor, role: TeamRoles.owner),
    );

    return team;
  }

  /// The teams [actor] belongs to.
  Future<List<Team>> listTeams(TeamActor actor) async {
    final teams = <Team>[];
    for (final m in await store.membershipsOfUser(actor.userId)) {
      final team = await store.findTeam(m.teamId);
      if (team != null) teams.add(team);
    }

    return teams;
  }

  /// The teams [userId] owns: what account deletion must refuse on,
  /// because deleting the account would leave each of them without
  /// its owner. Not an actor-scoped call: the account-deletion action asks
  /// it about the caller.
  Future<List<Team>> ownedTeams(String userId) async {
    final teams = <Team>[];
    for (final m in await store.membershipsOfUser(userId)) {
      if (m.role != TeamRoles.owner) continue;
      final team = await store.findTeam(m.teamId);
      if (team != null) teams.add(team);
    }

    return teams;
  }

  /// The retention hook for the history's personal data: replaces the email
  /// snapshot of every event older than [retention] by
  /// `MembershipEvent.formerMember` and returns how many events it changed.
  /// Idempotent. The user IDs, types, roles and times stay, so the audit
  /// trail stays intact; only the readable address goes. A scheduled job
  /// calls this (see `backend/appwrite/README.md`, "Team tenancy").
  Future<int> redactEmailsOlderThan(Duration retention) =>
      store.redactEventEmails(
        before: _clock().subtract(retention),
        marker: MembershipEvent.formerMember,
      );

  /// The members of [teamId]; any member may ask.
  Future<List<Membership>> listMembers(TeamActor actor, String teamId) async {
    await _membership(actor, teamId);

    return await store.membershipsOfTeam(teamId);
  }

  /// Invites [email] to [teamId] as [role].
  Future<Invitation> invite(
    TeamActor actor,
    String teamId, {
    required String email,
    required String role,
  }) async {
    final me = await _manager(actor, teamId);
    _requireGrantable(me, role);
    final normalised = _normalise(email);
    if (!normalised.contains('@')) {
      throw const TeamInvariantError('An invitation needs an email address.');
    }
    final members = await store.membershipsOfTeam(teamId);
    if (members.any((m) => m.email == normalised)) {
      throw const TeamInvitationError('That person is already a member.');
    }
    final open = await _sweep(await store.invitationsOfTeam(teamId));
    if (open.any((i) => i.isPendingFor(normalised))) {
      throw const TeamInvitationError('That person is already invited.');
    }
    final now = _clock();
    final team = await store.findTeam(teamId);
    final invitation = Invitation(
      id: _newId(),
      teamId: teamId,
      teamName: team?.name ?? '',
      email: normalised,
      role: role,
      invitedBy: actor.userId,
      createdAt: now,
      expiresAt: now.add(invitationLifetime),
    );
    await store.saveInvitation(invitation);
    await _record(
      MembershipEventType.invited,
      teamId,
      actor,
      _Detail(subjectEmail: normalised, role: role),
    );

    return invitation;
  }

  /// The invitations of [teamId], any status (expiry applied first).
  Future<List<Invitation>> listInvitations(
    TeamActor actor,
    String teamId,
  ) async {
    await _manager(actor, teamId);

    return await _sweep(await store.invitationsOfTeam(teamId));
  }

  /// The pending invitations addressed to [actor]'s email.
  Future<List<Invitation>> listMyInvitations(TeamActor actor) async {
    final all = await _sweep(
      await store.invitationsForEmail(_normalise(actor.email)),
    );

    return all.where((i) => i.isPending).toList();
  }

  /// Accepts [invitationId] for [actor], who must hold the invited email.
  Future<Membership> acceptInvitation(
    TeamActor actor,
    String invitationId,
  ) async {
    final invitation = await _pendingInvitation(
      invitationId,
      forEmail: _normalise(actor.email),
    );
    final membership = invitation.acceptedBy(actor.userId, _clock());
    await store.saveMembership(membership);
    await store.saveInvitation(
      invitation.withStatus(InvitationStatus.accepted),
    );
    await _record(
      MembershipEventType.accepted,
      invitation.teamId,
      actor,
      _Detail(subject: actor, role: invitation.role),
    );

    return membership;
  }

  /// Withdraws a pending invitation.
  Future<void> revokeInvitation(TeamActor actor, String invitationId) async {
    final invitation = await _pendingInvitation(invitationId);
    final me = await _manager(actor, invitation.teamId);
    _requireCanManage(me, invitation.role, 'revoke');
    await store.saveInvitation(invitation.withStatus(InvitationStatus.revoked));
    await _record(
      MembershipEventType.revoked,
      invitation.teamId,
      actor,
      _Detail(subjectEmail: invitation.email, role: invitation.role),
    );
  }

  /// The invitation [invitationId], expiry applied, which must still be
  /// pending. With [forEmail], an invitation addressed to someone else is
  /// "not found", never "not yours".
  Future<Invitation> _pendingInvitation(
    String invitationId, {
    String? forEmail,
  }) async {
    final found = await store.findInvitation(invitationId);
    if (found == null || (forEmail != null && found.email != forEmail)) {
      throw const TeamNotFoundError('No such invitation.');
    }

    return (await _sweep(<Invitation>[found])).single..requirePending();
  }

  /// Removes [userId] from [teamId].
  Future<void> removeMember(
    TeamActor actor,
    String teamId, {
    required String userId,
  }) async {
    if (userId == actor.userId) return await leaveTeam(actor, teamId);
    await _heal(teamId);
    final me = await _manager(actor, teamId);
    final target = await _target(teamId, userId);
    if (target.role == TeamRoles.owner) {
      throw const TeamInvariantError(
        "The owner can't be removed; transfer ownership first.",
      );
    }
    _requireCanManage(me, target.role, 'remove');
    await store.deleteMembership(teamId, userId);
    await _record(
      MembershipEventType.removed,
      teamId,
      actor,
      _Detail(
        subject: TeamActor(userId: userId, email: target.email),
        role: target.role,
      ),
    );
  }

  /// [actor] leaves [teamId].
  Future<void> leaveTeam(TeamActor actor, String teamId) async {
    await _heal(teamId);
    final me = await _membership(actor, teamId);
    if (me.role == TeamRoles.owner) {
      throw const TeamInvariantError(
        "The owner can't leave; transfer ownership first.",
      );
    }
    await store.deleteMembership(teamId, actor.userId);
    await _record(
      MembershipEventType.left,
      teamId,
      actor,
      _Detail(subject: actor, role: me.role),
    );
  }

  /// Changes [userId]'s role in [teamId] to [role].
  Future<Membership> changeRole(
    TeamActor actor,
    String teamId, {
    required String userId,
    required String role,
  }) async {
    await _heal(teamId);
    final me = await _manager(actor, teamId);
    final target = await _target(teamId, userId);
    if (target.role == TeamRoles.owner) {
      throw const TeamInvariantError(
        "The owner's role can only change by transferring ownership.",
      );
    }
    _requireGrantable(me, role);
    _requireCanManage(me, target.role, 'change');
    final updated = target.withRole(role);
    await store.saveMembership(updated);
    await _record(
      MembershipEventType.roleChanged,
      teamId,
      actor,
      _Detail(
        subject: TeamActor(userId: userId, email: target.email),
        role: role,
        previousRole: target.role,
      ),
    );

    return updated;
  }

  /// Moves ownership of [teamId] from [actor] to [toUserId].
  Future<void> transferOwnership(
    TeamActor actor,
    String teamId, {
    required String toUserId,
  }) async {
    await _heal(teamId);
    final me = await _membership(actor, teamId);
    if (me.role != TeamRoles.owner) {
      throw const TeamPermissionError('Only the owner can transfer ownership.');
    }
    if (toUserId == actor.userId) {
      throw const TeamInvariantError('You already own this team.');
    }
    final target = await _target(teamId, toUserId);
    // Event first: it is what `_heal` uses to finish a transfer that failed
    // between the next two writes.
    await _record(
      MembershipEventType.ownershipTransferred,
      teamId,
      actor,
      _Detail(
        subject: TeamActor(userId: toUserId, email: target.email),
        role: TeamRoles.owner,
        previousRole: target.role,
      ),
    );
    await store.saveMembership(target.withRole(TeamRoles.owner));
    await store.saveMembership(me.withRole(TeamRoles.admin));
  }

  /// The history of [teamId], oldest first.
  Future<List<MembershipEvent>> history(TeamActor actor, String teamId) async {
    await _manager(actor, teamId);
    await _sweep(await store.invitationsOfTeam(teamId));

    return await store.eventsOfTeam(teamId);
  }

  Future<Membership> _membership(TeamActor actor, String teamId) async {
    final members = await store.membershipsOfTeam(teamId);
    for (final m in members) {
      if (m.userId == actor.userId) return m;
    }
    throw const TeamNotFoundError('No such team.');
  }

  Future<Membership> _manager(TeamActor actor, String teamId) async {
    final me = await _membership(actor, teamId);
    if (me.role != TeamRoles.owner && me.role != TeamRoles.admin) {
      throw const TeamPermissionError('Only the owner and admins can do this.');
    }

    return me;
  }

  Future<Membership> _target(String teamId, String userId) async {
    for (final m in await store.membershipsOfTeam(teamId)) {
      if (m.userId == userId) return m;
    }
    throw const TeamInvariantError('That person is not a member.');
  }

  /// [role] must be a role that may be granted at all, and [me] must be
  /// allowed to grant it (only the owner grants the admin role).
  void _requireGrantable(Membership me, String role) {
    // Never grantable, whatever `assignableRoles` an app configured: only
    // `transferOwnership` moves the owner role.
    if (role == TeamRoles.owner) {
      throw const TeamInvariantError(
        'The owner role can only be given by transferring ownership.',
      );
    }
    if (!assignableRoles.contains(role)) {
      throw TeamInvariantError('Unknown role "$role".');
    }
    _requireCanManage(me, role, 'grant');
  }

  /// [me] must be allowed to act on someone holding [role]: admins manage
  /// only members below admin.
  void _requireCanManage(Membership me, String role, String verb) {
    if (role == TeamRoles.admin && me.role != TeamRoles.owner) {
      throw TeamPermissionError('Only the owner can $verb the admin role.');
    }
  }

  /// Marks every pending invitation in [invitations] that has lapsed as
  /// expired, recording it, and returns the list with that applied.
  Future<List<Invitation>> _sweep(List<Invitation> invitations) async {
    final now = _clock();
    final result = <Invitation>[];
    for (final i in invitations) {
      if (i.hasLapsedAt(now)) {
        final expired = i.withStatus(InvitationStatus.expired);
        await store.saveInvitation(expired);
        await store.appendEvent(
          MembershipEvent.invitationExpired(
            id: _newId(),
            invitation: i,
            at: now,
          ),
        );
        result.add(expired);
      } else {
        result.add(i);
      }
    }

    return result;
  }

  /// Finishes an interrupted ownership transfer: if more than one member is
  /// the owner, only the recipient of the latest recorded transfer stays
  /// owner and the others become admins.
  Future<void> _heal(String teamId) async {
    final owners = (await store.membershipsOfTeam(
      teamId,
    )).where((m) => m.role == TeamRoles.owner).toList();
    if (owners.length <= 1) return;
    final transfers = (await store.eventsOfTeam(
      teamId,
    )).where((e) => e.type == MembershipEventType.ownershipTransferred);
    if (transfers.isEmpty) return;
    final keeper = transfers.last.subjectUserId;
    for (final o in owners.where((o) => o.userId != keeper)) {
      await store.saveMembership(o.withRole(TeamRoles.admin));
    }
  }

  Future<void> _record(
    MembershipEventType type,
    String teamId,
    TeamActor actor, [
    _Detail detail = const _Detail(),
  ]) {
    final subject = detail.subject;

    return store.appendEvent(
      MembershipEvent(
        id: _newId(),
        teamId: teamId,
        type: type,
        actorUserId: actor.userId,
        actorEmail: _normalise(actor.email),
        subjectUserId: subject?.userId,
        subjectEmail: subject == null
            ? detail.subjectEmail
            : _normalise(subject.email),
        role: detail.role,
        previousRole: detail.previousRole,
        at: _clock(),
      ),
    );
  }

  String _normalise(String email) => email.trim().toLowerCase();
}

/// The optional parts of an event [TeamEngine._record] writes.
class _Detail {
  const _Detail({
    this.subject,
    this.subjectEmail,
    this.role,
    this.previousRole,
  });

  final TeamActor? subject;
  final String? subjectEmail;
  final String? role;
  final String? previousRole;
}

class _SequentialIds {
  int _next = 0;

  String next() => 'id-${_next++}';
}
