// Test literals, `late` fixtures, `!` on a value the test just made and a
// do-nothing fake method are plain in a test.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_late_keyword, solid_lints/avoid_non_null_assertion, solid_lints/prefer_match_file_name, solid_lints/no_empty_block, solid_lints/avoid_returning_widgets

import 'package:app/app/billing_owner_resolver.dart';
import 'package:billing/billing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/team_test_world.dart';

void main() {
  late TeamTestWorld world;

  setUp(() {
    world = TeamTestWorld();
  });

  BillingOwnerResolver resolverFor(TeamTestUser user) =>
      BillingOwnerResolver(user.auth, user.teams, user.active);

  test('nobody signed in: no owner', () async {
    expect(await resolverFor(world.ada).resolve(), isNull);
  });

  test('signed in with no team: the user', () async {
    await world.ada.auth.restoreSession();

    expect(
      await resolverFor(world.ada).resolve(),
      const BillingOwner.user('ada-id'),
    );
  });

  test('the active team, when the user belongs to it: team-first', () async {
    await world.ada.auth.restoreSession();
    final team = await world.ada.teams.createTeam('Agency');
    await world.ada.active.switchTo(team.id);

    expect(await resolverFor(world.ada).resolve(), BillingOwner.team(team.id));
  });

  test('a stored team the user is not in falls back to the user', () async {
    await world.grace.auth.restoreSession();
    await world.ada.auth.restoreSession();
    final adas = await world.ada.teams.createTeam('Agency');
    await world.grace.active.switchTo(adas.id);

    expect(
      await resolverFor(world.grace).resolve(),
      const BillingOwner.user('grace-id'),
    );
  });
}
