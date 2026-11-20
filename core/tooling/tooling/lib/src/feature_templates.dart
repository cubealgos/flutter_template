import 'package:tooling/src/feature_names.dart';

/// How many `../` beyond the feature's own depth a test file needs to reach
/// `test/support/`: the view test sits in `test/features/<path>/`.
const int _viewTestExtraDepth = 1;

/// As [_viewTestExtraDepth], for a test in the feature's `layouts/` folder.
const int _layoutTestExtraDepth = 2;

/// Source text of every file `new_feature` generates, as plain string
/// builders (no template engine). [appPackage] is the app's package name
/// (read from `apps/app/pubspec.yaml`, so a renamed clone still works).
///
/// The text is not hand-wrapped to 80 columns: `NewFeatureCommand` runs
/// `dart format` over everything it writes.
class FeatureTemplates {
  /// Creates the templates for [names] in package [appPackage].
  const FeatureTemplates(this.names, {required this.appPackage});

  /// The names derived from the feature path.
  final FeatureNames names;

  /// The app's Dart package name.
  final String appPackage;

  String get _feature => 'package:$appPackage/features/${names.path}';

  String get _pascal => names.pascal;

  /// Sorted `package:` import block for [uris].
  String _imports(List<String> uris) {
    final sorted = List<String>.of(uris)..sort();

    return sorted.map((uri) => "import '$uri';").join('\n');
  }

  /// `<n>_model.dart`: an empty, hand-written immutable model (no codegen).
  String model() =>
      '''
import 'package:mvc/mvc.dart';

/// `${_pascal}View`'s view model. Empty until the screen has state of its
/// own; turn it into a `@freezed` class (and run `melos run gen`) when it
/// grows fields.
class ${_pascal}Model implements ViewModel {
  /// Creates the model.
  const ${_pascal}Model();
}
''';

  /// `<n>_controller.dart`.
  String controller() =>
      '''
${_imports(<String>['$_feature/${names.name}_model.dart', 'package:mvc/mvc.dart'])}

/// Drives `${_pascal}View`: navigates back, nothing else yet.
///
/// Navigates only through the injected [NavigationService], per the MVC
/// controller rule enforced by `core/architecture/mvc_lints`.
class ${_pascal}Controller extends ViewController<${_pascal}Model> {
  /// Creates the controller.
  ${_pascal}Controller(this._navigation) : super(const ${_pascal}Model());

  final NavigationService _navigation;

  /// Pops back to the previous screen, if there is one to pop back to.
  void goBack() {
    if (_navigation.canPop()) _navigation.pop();
  }
}
''';

  /// `<n>_view.dart`: the feature's only `ViewWidget`.
  String view() =>
      '''
${_imports(<String>['package:$appPackage/app/di.dart', '$_feature/layouts/${names.name}_mobile_layout.dart', '$_feature/${names.name}_controller.dart', '$_feature/${names.name}_model.dart', 'package:flutter/widgets.dart', 'package:mvc/mvc.dart'])}

/// The ${names.title} screen.
///
/// The only `ViewWidget` of the feature: it owns the controller and builds a
/// `ResponsiveLayout` of `${_pascal}MobileLayout` (mobile only — every wider
/// viewport falls back to it).
///
/// Stays dumb per the MVC view rule: no navigation, no service imports
/// beyond the injected controller — enforced by `core/architecture/mvc_lints`.
class ${_pascal}View extends ViewWidget<${_pascal}Model, ${_pascal}Controller> {
  /// Creates the view.
  ${_pascal}View({super.key});

  @override
  ${_pascal}Controller createController() =>
      ${_pascal}Controller(getIt<NavigationService>());

  @override
  Widget build(
    BuildContext context,
    ${_pascal}Controller controller,
    ${_pascal}Model model,
  ) {
    return ResponsiveLayout(
      mobile: (_) =>
          ${_pascal}MobileLayout(model: model, onBack: controller.goBack),
    );
  }
}
''';

  /// `layouts/<n>_mobile_layout.dart`: a dumb widget with callbacks only.
  String mobileLayout() =>
      '''
${_imports(<String>['$_feature/${names.name}_model.dart', 'package:$appPackage/i18n/strings.g.dart', 'package:flutter/widgets.dart', 'package:ui/ui.dart'])}

/// The ${names.title} screen's mobile layout (also the fallback for every
/// wider viewport until a tablet or desktop layout exists). Dumb: it renders
/// [model] and reports taps through its callbacks.
class ${_pascal}MobileLayout extends StatelessWidget {
  /// Creates the layout.
  const ${_pascal}MobileLayout({
    required this.model,
    required this.onBack,
    super.key,
  });

  /// The screen title. Placeholder copy: move it into
  /// `lib/i18n/en.i18n.json` and `de.i18n.json` (then `melos run gen`) and
  /// read it through `t` like the other screens do.
  static const String title = '${names.title}';

  /// The state to render.
  final ${_pascal}Model model;

  /// Called when the back chevron is pressed.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: title,
      back: AppScreenHeaderBack(
        semanticLabel: t.common.back,
        onPressed: onBack,
      ),
      // Build the screen here, from the model and callbacks passed in.
      body: const AppGap.v2(),
    );
  }
}
''';

  /// `test/.../<n>_view_test.dart`: a light and dark smoke test.
  String viewTest() {
    final up = '../' * (names.segments.length + _viewTestExtraDepth);

    return '''
${_imports(<String>['package:$appPackage/app/di.dart', '$_feature/${names.name}_view.dart', 'package:flutter/widgets.dart', 'package:flutter_test/flutter_test.dart'])}

import '${up}support/screen_harness.dart';

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  for (final brightness in Brightness.values) {
    testWidgets('renders in \${brightness.name} without throwing', (
      tester,
    ) async {
      await pumpScreen(tester, ${_pascal}View(), brightness: brightness);
      await tester.pumpAndSettle();

      expect(find.byType(${_pascal}View), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
''';
  }

  /// `test/.../layouts/<n>_mobile_layout_test.dart`.
  String layoutTest() {
    final up = '../' * (names.segments.length + _layoutTestExtraDepth);

    return '''
${_imports(<String>['$_feature/layouts/${names.name}_mobile_layout.dart', '$_feature/${names.name}_model.dart', 'package:flutter_test/flutter_test.dart'])}

import '${up}support/layout_harness.dart';

void main() {
  testWidgets('${_pascal}MobileLayout renders its title', (tester) async {
    await pumpLayout(
      tester,
      const ${_pascal}MobileLayout(model: ${_pascal}Model(), onBack: noop),
      width: mobileWidth,
    );

    expect(find.text(${_pascal}MobileLayout.title), findsOneWidget);
  });
}
''';
  }

  /// The `TypedGoRoute` entry for the `routes:` list (already indented).
  String routeEntry() =>
      "    TypedGoRoute<${names.routeClass}>(path: '${names.routePath}'),";

  /// The `import` line `router.dart` needs for the view.
  String routerImport() => "import '$_feature/${names.name}_view.dart';";

  /// The `GoRouteData` class appended to `router.dart`.
  String routeClassSource() =>
      '''
/// The ${names.title} route.
class ${names.routeClass} extends GoRouteData with \$${names.routeClass} {
  /// Creates the ${names.title} route.
  const ${names.routeClass}();

  @override
  Widget build(BuildContext context, GoRouterState state) => ${_pascal}View();
}
''';

  /// What to add to `router.dart` by hand when it cannot be edited safely.
  String manualSnippet() =>
      "${routerImport()}\n\n// In BootstrapRoute's routes: list\n"
      '${routeEntry()}\n\n${routeClassSource()}';
}
