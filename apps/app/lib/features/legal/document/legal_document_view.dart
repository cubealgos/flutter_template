import 'package:app/app/config.dart';
import 'package:app/app/di.dart';
import 'package:app/features/legal/document/layouts/legal_document_mobile_layout.dart';
import 'package:app/features/legal/document/legal_document_controller.dart';
import 'package:app/features/legal/document/legal_document_model.dart';
import 'package:app/features/legal/document/legal_document_type.dart';
import 'package:flutter/widgets.dart';
import 'package:mvc/mvc.dart';

/// Renders one of the plan's four legal documents (Impressum, Datenschutz,
/// AGB, Barrierefreiheit), built entirely from `AppConfig`'s placeholder
/// legal-entity facts inside clearly marked template text — **never real
/// company data**; a cloned app replaces `AppConfig`'s field values with
/// its own lawyer-reviewed facts (see `AppConfig`'s dartdoc).
///
/// The only `ViewWidget` of the feature: it owns the controller and builds a
/// `ResponsiveLayout` of `LegalDocumentMobileLayout` (mobile only — every wider
/// viewport falls back to it).
///
/// Stays dumb per the MVC view rule: no navigation, no service imports
/// beyond the injected controller — enforced by `core/architecture/mvc_lints`.
class LegalDocumentView
    extends ViewWidget<LegalDocumentModel, LegalDocumentController> {
  /// Creates the view for [type].
  LegalDocumentView({required this.type, super.key});

  /// Which document to render.
  final LegalDocumentType type;

  @override
  LegalDocumentController createController() =>
      LegalDocumentController(getIt<NavigationService>(), type: type);

  @override
  Widget build(
    BuildContext context,
    LegalDocumentController controller,
    LegalDocumentModel model,
  ) {
    return ResponsiveLayout(
      mobile: (_) => LegalDocumentMobileLayout(
        type: model.type,
        config: getIt<AppConfig>(),
        onBack: controller.goBack,
      ),
    );
  }
}
