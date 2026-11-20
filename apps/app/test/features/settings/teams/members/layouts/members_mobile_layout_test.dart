import 'package:app/features/settings/teams/members/layouts/members_mobile_layout.dart';
import 'package:app/features/settings/teams/members/members_model.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teams/teams.dart';

import '../../../../../support/layout_harness.dart';

Future<void> _pump(WidgetTester tester, MembersModel model) => pumpLayout(
  tester,
  MembersMobileLayout(
    model: model,
    emailController: TextEditingController(),
    onBack: noop,
    onInvite: noop,
    onRevoke: noop,
    onLeave: noop,
  ),
  width: mobileWidth,
);

MembersModel _model(String myRole) => MembersModel(
  loading: false,
  team: const Team(id: 't', name: 'Acme'),
  myRole: myRole,
  members: <Membership>[
    Membership(
      teamId: 't',
      userId: 'u1',
      email: 'owner@example.com',
      role: TeamRoles.owner,
      joinedAt: DateTime.utc(2026),
    ),
    Membership(
      teamId: 't',
      userId: 'u2',
      email: 'member@example.com',
      role: 'auditor',
      joinedAt: DateTime.utc(2026),
    ),
  ],
  pendingInvitations: <Invitation>[
    Invitation(
      id: 'i',
      teamId: 't',
      teamName: 'Acme',
      email: 'new@example.com',
      role: TeamRoles.member,
      invitedBy: 'u1',
      createdAt: DateTime.utc(2026),
      expiresAt: DateTime.utc(2026, 1, 8),
    ),
  ],
);

void main() {
  testWidgets('the owner sees the invite form and pending invitations, '
      'but cannot leave', (tester) async {
    await _pump(tester, _model(TeamRoles.owner));

    expect(find.text('owner@example.com'), findsOneWidget);
    expect(find.text('Owner'), findsOneWidget);
    expect(find.text('auditor'), findsOneWidget, reason: 'custom role as is');
    expect(find.text('Send invitation'), findsWidgets);
    expect(find.text('new@example.com'), findsOneWidget);
    expect(find.text('Expires 2026-01-08'), findsOneWidget);
    expect(find.text('Leave team'), findsNothing);
  });

  testWidgets('a plain member sees no invite form, and can leave', (
    tester,
  ) async {
    await _pump(tester, _model(TeamRoles.member));

    expect(find.text('Send invitation'), findsNothing);
    expect(find.text('Leave team'), findsWidgets);
  });

  testWidgets('without a team it says to create one', (tester) async {
    await _pump(tester, const MembersModel(loading: false));

    expect(find.text('Create or pick a team first.'), findsOneWidget);
  });
}
