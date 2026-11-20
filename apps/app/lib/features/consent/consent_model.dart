import 'package:mvc/mvc.dart';

/// `ConsentView`'s view model. Empty on purpose: Accept/Reject are one-shot
/// actions the controller handles directly (navigating away immediately),
/// so there is no in-progress state for this screen to render — see
/// `ConsentController`.
class ConsentModel implements ViewModel {
  /// Creates the model.
  const ConsentModel();
}
