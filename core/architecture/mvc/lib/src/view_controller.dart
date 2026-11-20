// Vendored from sprout_state 0.3.0 (packages/sprout_state/lib/src/view_controller.dart),
// unchanged — see lib/mvc.dart for the vendoring note.
part of '../mvc.dart';

/// Holds a screen's behaviour and its current immutable [model], notifying
/// listeners whenever the model changes.
///
/// A `ValueNotifier<M>`: push a new immutable model via
/// `value = value.copyWith(...)`. [init] runs once when the owning
/// [ViewWidget] mounts; `dispose()` (from `ValueNotifier`) is called when it
/// unmounts.
abstract class ViewController<M extends ViewModel> extends ValueNotifier<M> {
  /// Creates the controller with its initial model as the notifier's
  /// starting value.
  //
  // `ValueNotifier`'s own positional parameter is the private `_value`,
  // which this package cannot name from outside its library — `super.value`
  // is this constructor's clearest available name for the same argument.
  // This is a core `package:lints` diagnostic (not a solid_lints one), so
  // the ignore below is intentionally unnamespaced.
  // ignore: matching_super_parameters
  ViewController(super.value);

  /// The current immutable model (the notifier's `value`).
  M get model => value;

  /// Called once when the controller is first mounted by a view. Override
  /// to kick off loads/subscriptions.
  //
  // Deliberately empty: this is the default no-op, part of the vendored
  // sprout_state API — most controllers never override it.
  // ignore: solid_lints/no_empty_block
  void init() {}
}
