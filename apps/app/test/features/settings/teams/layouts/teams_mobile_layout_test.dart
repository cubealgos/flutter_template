import 'package:app/features/settings/teams/layouts/teams_mobile_layout.dart';
import 'package:app/features/settings/teams/teams_model.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teams/teams.dart';

import '../../../../support/layout_harness.dart';

Future<void> _pump(
  WidgetTester tester,
  TeamsModel model, {
  ValueChanged<String> onSwitch = noop,
  ValueChanged<String> onAccept = noop,
}) => pumpLayout(
  tester,
  TeamsMobileLayout(
    model: model,
    nameController: TextEditingController(),
    onBack: noop,
    onCreate: noop,
    onSwitch: onSwitch,
    onAccept: onAccept,
    onOpenMembers: noop,
  ),
  width: mobileWidth,
);

void main() {
  testWidgets('shows the empty state and the create form', (tester) async {
    await _pump(tester, const TeamsModel(loading: false));

    expect(find.text("You aren't in a team yet."), findsOneWidget);
    expect(find.text('Create team'), findsWidgets);
  });

  testWidgets('marks the active team and switches to another', (tester) async {
    String? switched;
    await _pump(
      tester,
      const TeamsModel(
        loading: false,
        teams: <Team>[
          Team(id: 'a', name: 'Alpha'),
          Team(id: 'b', name: 'Beta'),
        ],
        activeTeamId: 'a',
      ),
      onSwitch: (id) => switched = id,
    );

    expect(find.text('Active team'), findsOneWidget);
    expect(find.text('Members'), findsOneWidget);
    await tester.tap(find.text('Switch'));

    expect(switched, 'b');
  });

  testWidgets('lists an invitation with an Accept button', (tester) async {
    String? accepted;
    await _pump(
      tester,
      TeamsModel(
        loading: false,
        invitations: <Invitation>[
          Invitation(
            id: 'i1',
            teamId: 't',
            teamName: 'Gamma',
            email: 'a@example.com',
            role: 'member',
            invitedBy: 'u',
            createdAt: DateTime.utc(2026),
            expiresAt: DateTime.utc(2026, 2),
          ),
        ],
      ),
      onAccept: (id) => accepted = id,
    );

    expect(find.text('Gamma'), findsOneWidget);
    await tester.tap(find.text('Accept'));

    expect(accepted, 'i1');
  });

  testWidgets('shows the failure message', (tester) async {
    await _pump(tester, const TeamsModel(loading: false, failed: true));

    expect(find.textContaining("didn't work"), findsOneWidget);
  });
}
