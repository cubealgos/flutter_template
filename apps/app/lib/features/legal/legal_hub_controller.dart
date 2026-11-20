import 'package:app/app/config.dart';
import 'package:app/app/router.dart';
import 'package:app/features/legal/legal_hub_model.dart';
import 'package:mvc/mvc.dart';

/// Drives `LegalHubView`: navigates to each legal document, plus back.
///
/// Reachable in one tap from the sign-in screen and from the Settings hub
/// (both pre- and post-login), satisfying the plan's "reachable in two
/// taps or fewer, even before login" requirement together with each
/// document being one further tap from here.
class LegalHubController extends ViewController<LegalHubModel> {
  /// Creates the controller, reading [config] once for the
  /// Barrierefreiheit row's visibility.
  LegalHubController(this._navigation, AppConfig config)
    : super(
        LegalHubModel(
          showAccessibilityStatement: config.accessibilityStatement,
        ),
      );

  final NavigationService _navigation;

  /// Opens the Impressum document.
  void openImpressum() => _navigation.push(const ImpressumRoute().location);

  /// Opens the Datenschutz document.
  void openDatenschutz() => _navigation.push(const DatenschutzRoute().location);

  /// Opens the AGB document.
  void openAgb() => _navigation.push(const AgbRoute().location);

  /// Opens the Barrierefreiheit document.
  void openBarrierefreiheit() =>
      _navigation.push(const BarrierefreiheitRoute().location);

  /// Opens the OSS licences page.
  void openLicences() => _navigation.push(const LicencesRoute().location);

  /// Pops back to the previous screen, if there is one to pop back to.
  void goBack() {
    if (_navigation.canPop()) _navigation.pop();
  }
}
