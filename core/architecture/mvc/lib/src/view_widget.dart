// Vendored from sprout_state 0.3.0 (packages/sprout_state/lib/src/view_widget.dart),
// unchanged — see lib/mvc.dart for the vendoring note.
part of '../mvc.dart';

/// A dumb, per-screen view: it owns a [ViewController] of type [C] and
/// rebuilds [build] whenever the controller pushes a new [M].
///
/// Every screen subclasses this. Implement [createController] to construct
/// the screen's controller (typically with injected services) and [build]
/// to render the current model. The controller is created once and lives on
/// the [State], not the widget — see `_ViewWidgetState.controller` below for
/// why a `late final` field, not the widget, has to own it.
abstract class ViewWidget<M extends ViewModel, C extends ViewController<M>>
    extends StatefulWidget {
  /// Creates the view. Non-const so subclasses (every screen) aren't pushed
  /// toward const constructors by `prefer_const_constructors_in_immutables`
  /// — a view's `createController` typically closes over injected services,
  /// which are rarely const-constructible themselves.
  // ignore: prefer_const_constructors_in_immutables
  ViewWidget({super.key});

  /// Called once, from [State.initState], after the controller has been
  /// created but before its own [ViewController.init]. Override for
  /// widget-level setup that isn't controller behaviour.
  //
  // Deliberately empty: this is the default no-op, part of the vendored
  // sprout_state API — most views never override it.
  // ignore: solid_lints/no_empty_block
  void initState() {}

  /// Creates this screen's controller. Called exactly once, the first time
  /// the view mounts — never again across parent rebuilds (see
  /// `_ViewWidgetState.controller`).
  C createController();

  @override
  State<ViewWidget<M, C>> createState() => _ViewWidgetState<M, C>();

  /// Renders the current model, with [controller] available for wiring up
  /// callbacks (e.g. `onTap: controller.submit`).
  Widget build(BuildContext context, C controller, M model);
}

class _ViewWidgetState<M extends ViewModel, C extends ViewController<M>>
    extends State<ViewWidget<M, C>> {
  // The controller is owned by the State, not the widget: a StatefulWidget
  // is rebuilt (a fresh instance) on every parent rebuild, so a controller
  // held on the widget would be recreated — and left un-`init()`ed — each
  // time, dropping its synced state. The State persists across those
  // rebuilds, so the controller created here is created and `init()`ed
  // exactly once. `late` is load-bearing, not stylistic: `widget` isn't
  // attached until after this State's own constructor returns, so a
  // non-`late` initializer would read it too early.
  // ignore: solid_lints/avoid_late_keyword
  late final C controller = widget.createController();

  @override
  void initState() {
    super.initState();
    widget.initState();
    controller.init();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ViewControllerInjector(
      controller: controller,
      child: ValueListenableBuilder<M>(
        valueListenable: controller,
        builder: (context, model, _) {
          return widget.build(context, controller, model);
        },
      ),
    );
  }
}
