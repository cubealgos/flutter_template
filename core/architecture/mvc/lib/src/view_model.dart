// Vendored from sprout_state 0.3.0 (packages/sprout_state/lib/src/view_model.dart),
// unchanged — see lib/mvc.dart for the vendoring note.
part of '../mvc.dart';

/// Marker base for an immutable, per-screen view model.
///
/// App view models are typically `freezed` classes that extend this. It
/// carries no behaviour — behaviour lives on the [ViewController]. It
/// exists so [ViewController] can be parameterised by a model type.
abstract class ViewModel {
  /// Const constructor for subclasses (typically a `freezed` class' generated
  /// constructor) to forward to.
  const ViewModel();
}
