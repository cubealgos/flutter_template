// Vendored from sprout_state 0.3.0
// (packages/sprout_state/lib/src/inherited_view_widget.dart), unchanged —
// see lib/mvc.dart for the vendoring note.
part of '../mvc.dart';

/// A dumb, nested widget that reads an ancestor [ViewWidget]'s controller
/// and rebuilds whenever that controller pushes a new model.
///
/// Unlike [ViewWidget], this does not create or own a controller — it looks
/// one up from the nearest enclosing [ViewWidget] of matching type via
/// [_ViewControllerInjector], so a subtree can share a screen's controller
/// without it being threaded through every constructor by hand.
abstract class InheritedViewWidget<
  M extends ViewModel,
  C extends ViewController<M>
>
    extends StatefulWidget {
  /// Creates the widget.
  const InheritedViewWidget({super.key});

  /// Called once, from [State.initState]. Override for setup that isn't
  /// controller behaviour.
  //
  // Deliberately empty: this is the default no-op, part of the vendored
  // sprout_state API — most nested views never override it.
  // ignore: solid_lints/no_empty_block
  void initState() {}

  @override
  State<InheritedViewWidget<M, C>> createState() =>
      _InheritedViewWidgetState<M, C>();

  /// Renders the current model read from the ancestor [controller].
  Widget build(BuildContext context, C controller, M model);
}

class _InheritedViewWidgetState<
  M extends ViewModel,
  C extends ViewController<M>
>
    extends State<InheritedViewWidget<M, C>> {
  @override
  void initState() {
    super.initState();
    widget.initState();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _ViewControllerInjector.of<C>(context).controller;

    return ValueListenableBuilder<M>(
      valueListenable: controller,
      builder: (context, model, _) {
        return widget.build(context, controller, model);
      },
    );
  }
}
