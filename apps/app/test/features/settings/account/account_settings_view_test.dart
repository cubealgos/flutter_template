import 'package:app/app/di.dart';
import 'package:app/features/settings/account/account_settings_view.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:auth/auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teams/teams.dart';
import 'package:ui/ui.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    configureDependencies();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
    'critical flow: delete account — confirm dialog, then the account is '
    'actually deleted, with no support-ticket step',
    (tester) async {
      final auth = getIt<AuthService>() as FakeAuthService;
      await auth.signInWithPasskey();
      expect(auth.currentSession, isNotNull);

      // OverlayDialogService (behind the injected DialogService) shows
      // its overlay above the app's shared navigatorKey, so this needs a
      // real Navigator using that same key attached — not just the bare
      // view.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: AppTheme(
              child: Navigator(
                key: getIt<GlobalKey<NavigatorState>>(),
                onGenerateRoute: (_) => PageRouteBuilder<void>(
                  pageBuilder: (_, _, _) => AccountSettingsView(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.settings.account.deleteAccountButton));
      await tester.pumpAndSettle();

      // The confirmation dialog — the one and only extra step; no
      // support ticket, no separate screen.
      expect(find.text(t.settings.account.deleteConfirmTitle), findsOneWidget);

      await tester.tap(find.text(t.settings.account.deleteConfirmButton));
      await tester.pumpAndSettle();

      expect(auth.currentSession, isNull);
    },
  );

  testWidgets(
    'the page-level delete-account button is outlined, not filled — only '
    'the confirmation dialog\'s own "Delete" is filled destructive',
    (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: AppTheme(
              child: Navigator(
                key: getIt<GlobalKey<NavigatorState>>(),
                onGenerateRoute: (_) => PageRouteBuilder<void>(
                  pageBuilder: (_, _, _) => AccountSettingsView(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.variant, AppButtonVariant.destructiveOutlined);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('renders in ${brightness.name} without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(platformBrightness: brightness),
            child: AppTheme(
              brightnessOverride: brightness,
              child: Navigator(
                key: getIt<GlobalKey<NavigatorState>>(),
                onGenerateRoute: (_) => PageRouteBuilder<void>(
                  pageBuilder: (_, _, _) => AccountSettingsView(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccountSettingsView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('an owner who confirms deletion sees the refusal naming the '
      'team, and stays signed in', (tester) async {
    final auth = getIt<AuthService>() as FakeAuthService;
    await auth.signInWithPasskey();
    await getIt<TeamService>().createTeam('Acme');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: AppTheme(
            child: Navigator(
              key: getIt<GlobalKey<NavigatorState>>(),
              onGenerateRoute: (_) => PageRouteBuilder<void>(
                pageBuilder: (_, _, _) => AccountSettingsView(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.settings.account.deleteAccountButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.settings.account.deleteConfirmButton));
    await tester.pumpAndSettle();

    expect(
      find.text(t.settings.account.deleteOwnsTeams(teams: '"Acme"')),
      findsOneWidget,
    );
    expect(auth.currentSession, isNotNull);
  });
}
