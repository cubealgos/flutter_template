// Vendored from sprout_state 0.3.0
// (packages/sprout_state/lib/src/view_controller_injector.dart), unchanged —
// see lib/mvc.dart for the vendoring note.
part of '../mvc.dart';

// Private plumbing shared by ViewWidget and InheritedViewWidget: an
// InheritedWidget that makes the screen's controller available to
// InheritedViewWidget.of without threading it through every constructor.
// Not part of the package's public API, so it carries no dartdoc.
class _ViewControllerInjector<T extends ViewController>
    extends InheritedWidget {
  const _ViewControllerInjector({
    required this.controller,
    required super.child,
    super.key,
  });

  // Returning the injector widget itself (not extracted to a class) is the
  // vendored sprout_state API for this private lookup helper, not a widget
  // meant to be built directly.
  // ignore: solid_lints/avoid_returning_widgets
  /// Looks up the nearest enclosing [_ViewControllerInjector] of matching
  /// controller type — how [InheritedViewWidget] finds its ancestor
  /// [ViewWidget]'s controller.
  static _ViewControllerInjector<T> of<T extends ViewController>(
    BuildContext context,
  ) {
    // The bang assumes an ancestor exists, matching the original
    // sprout_state behaviour: [InheritedViewWidget] is only ever meant to
    // be used nested under a matching [ViewWidget], so a missing ancestor
    // here is a caller error that should surface immediately, not be
    // swallowed.
    // ignore: solid_lints/avoid_non_null_assertion
    return context
        .dependOnInheritedWidgetOfExactType<_ViewControllerInjector<T>>()!;
  }

  final T controller;

  @override
  bool updateShouldNotify(_ViewControllerInjector oldWidget) =>
      controller != oldWidget.controller;
}
