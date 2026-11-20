import 'package:app/features/legal/document/legal_document_model.dart';
import 'package:app/features/legal/document/legal_document_type.dart';
import 'package:mvc/mvc.dart';

/// Drives `LegalDocumentView`: exposes [goBack] so the view never calls
/// `NavigationService`/`Navigator` itself.
///
/// Reading `AppConfig`'s legal facts is left to the view directly (see
/// `LegalDocumentModel`'s dartdoc) — this controller's only behaviour is
/// navigation, so that's the only thing its test needs to mock.
class LegalDocumentController extends ViewController<LegalDocumentModel> {
  /// Creates the controller for [type], with [_navigation] injected — see
  /// `SampleController`-style constructors elsewhere in this app for why
  /// (a test can substitute a mock).
  LegalDocumentController(this._navigation, {required LegalDocumentType type})
    : super(LegalDocumentModel(type: type));

  final NavigationService _navigation;

  /// Pops back to the previous screen, if there is one to pop back to.
  void goBack() {
    if (_navigation.canPop()) _navigation.pop();
  }
}
