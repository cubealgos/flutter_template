import 'dart:io';

import 'package:app/app/di.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvc/mvc.dart';
import 'package:ui/ui.dart';

/// A no-op [NavigationService], swapped in for the real
/// `GoRouterNavigationService` before a screen smoke test pumps its
/// screen — several screens' controllers navigate from `init()` (e.g.
/// `BootstrapController`), which would otherwise reach for a real
/// `GoRouter` this bare harness never sets up (the per-screen smoke tests
/// mount one screen directly, not the full `App()`).
///
// This file holds both this class and the `pumpScreen` helper below, so
// neither name can match the file name alone.
// ignore: solid_lints/prefer_match_file_name
class NoOpNavigationService implements NavigationService {
  @override
  // Deliberately a no-op: this fake exists only so `init()`-time
  // navigation has somewhere harmless to go during a smoke test.
  // ignore: solid_lints/no_empty_block
  void go(String location) {}

  @override
  Future<T?> push<T extends Object?>(String location) async => null;

  @override
  // See [go]'s dartdoc.
  // ignore: solid_lints/no_empty_block
  void pop<T extends Object?>([T? result]) {}

  @override
  bool canPop() => false;

  @override
  Future<T?> replace<T extends Object?>(String location) async => null;
}

/// The height of the test view when a `width` is given.
const double _viewHeight = 800;

/// Pumps [screen] inside a minimal app shell at [brightness] — a
/// golden-free smoke test that a screen renders without throwing in both
/// themes (the per-screen acceptance criterion), reusing this
/// package's real DI (`configureDependencies()`, same as `app_test.dart`)
/// except for [NavigationService], swapped for [NoOpNavigationService] so
/// a controller's `init()`-time navigation never needs a real `GoRouter`.
///
/// Every screen pumped through here is also held to `flutter_test`'s
/// accessibility guidelines: [textContrastGuideline],
/// [labeledTapTargetGuideline], [androidTapTargetGuideline] and
/// [iOSTapTargetGuideline] are asserted against the settled screen as soon
/// as it is pumped, so it holds in both themes and every test that uses this
/// helper — including the ones `tooling:new_feature` generates — inherits
/// the check without writing it.
///
/// With [width], the test view is resized to that many logical pixels wide
/// (800 tall) and the screen follows it, so a test can pin a breakpoint.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  required Brightness brightness,
  double? width,
}) async {
  // Configures DI only if a caller's own `setUp` hasn't already done so —
  // `configureDependencies()` throws on a second call (get_it refuses a
  // duplicate registration), and some screens' existing test files (e.g.
  // `consent_view_test.dart`) already call it themselves before this smoke
  // test's own case runs.
  _stubPathProvider(tester);
  if (!getIt.isRegistered<NavigationService>()) {
    configureDependencies();
  }
  getIt
    ..unregister<NavigationService>()
    ..registerSingleton<NavigationService>(NoOpNavigationService());

  if (width != null) {
    tester.view
      ..physicalSize = Size(width, _viewHeight)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  // Paints the themed page background like `App`'s builder does: without
  // it the test surface is black, and the contrast guideline would measure
  // every screen's text against that instead of the real background.
  final app = AppTheme(
    brightnessOverride: brightness,
    child: Builder(
      builder: (context) =>
          ColoredBox(color: colorBg.resolve(context), child: screen),
    ),
  );
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: width == null
          ? MediaQuery(
              // Some screens (e.g. `PermissionPrePromptView`, shown via
              // `DialogService.show` outside the app's own `AppTheme`) wrap
              // themselves in their own un-overridden `AppTheme`, which
              // resolves brightness from this ambient `MediaQuery` rather
              // than the outer `AppTheme(brightnessOverride: ...)` — setting
              // `platformBrightness` here too makes both paths agree.
              data: MediaQueryData(platformBrightness: brightness),
              child: app,
            )
          : MediaQuery.fromView(view: tester.view, child: app),
    ),
  );
  await expectAccessible(tester);
}

/// Asserts the four accessibility guidelines against whatever [tester]
/// currently shows, with semantics on for the duration; [pumpScreen] calls
/// it with [settle] `true`. Call it directly with [settle] `false` for a
/// screen that must not settle.
Future<void> expectAccessible(WidgetTester tester, {bool settle = true}) async {
  final semantics = tester.ensureSemantics();
  try {
    if (settle) await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  } finally {
    semantics.dispose();
  }
}

/// Answers `path_provider`'s channel with the system temp directory.
///
/// The DI graph's Appwrite `Client` (built even on the default `fake`
/// backend, see `BackendModule.appwriteClient`) asks `path_provider` for a
/// cookie path as soon as it is constructed. With no plugin registered
/// that throws `MissingPluginException` — harmless while a test never
/// leaves fake time, but the accessibility guidelines capture a screenshot
/// in real time, which lets the failed future surface and fail the test.
void _stubPathProvider(WidgetTester tester) {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
    (_) async => Directory.systemTemp.path,
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    ),
  );
}
