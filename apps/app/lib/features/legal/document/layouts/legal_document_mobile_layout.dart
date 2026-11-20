import 'package:app/app/config.dart';
import 'package:app/features/legal/document/legal_document_type.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// One row of the placeholder legal text: a translated label next to an
/// `AppConfig` fact value.
class _Fact {
  const _Fact(this.label, this.value);

  final String label;
  final String value;
}

/// One of the four legal documents (Impressum, Datenschutz, AGB,
/// Barrierefreiheit) as a reading-width page: a template notice, an intro
/// and the `AppConfig` fact rows — **never real company data**.
class LegalDocumentMobileLayout extends StatelessWidget {
  /// Creates the layout.
  const LegalDocumentMobileLayout({
    required this.type,
    required this.config,
    required this.onBack,
    super.key,
  });

  /// Which document to render.
  final LegalDocumentType type;

  /// The placeholder legal-entity facts the document is built from.
  final AppConfig config;

  /// Called when the back chevron is pressed.
  final VoidCallback onBack;

  String _title(LegalDocumentType type) => switch (type) {
    LegalDocumentType.impressum => t.legal.impressum,
    LegalDocumentType.datenschutz => t.legal.datenschutz,
    LegalDocumentType.agb => t.legal.agb,
    LegalDocumentType.barrierefreiheit => t.legal.barrierefreiheit,
  };

  String _intro(LegalDocumentType type) => switch (type) {
    LegalDocumentType.impressum => t.legal.document.impressumIntro,
    LegalDocumentType.datenschutz => t.legal.document.datenschutzIntro,
    LegalDocumentType.agb => t.legal.document.agbIntro,
    LegalDocumentType.barrierefreiheit =>
      t.legal.document.barrierefreiheitIntro,
  };

  List<_Fact> _facts(LegalDocumentType type, AppConfig config) =>
      switch (type) {
        LegalDocumentType.impressum => <_Fact>[
          _Fact(t.legal.document.factCompanyName, config.legalCompanyName),
          _Fact(t.legal.document.factAddress, config.legalAddress),
          _Fact(t.legal.document.factRegister, config.legalRegister),
          _Fact(t.legal.document.factVatId, config.legalVatId),
          _Fact(t.legal.document.factContactEmail, config.legalContactEmail),
          _Fact(
            t.legal.document.factResponsiblePerson,
            config.legalResponsiblePerson,
          ),
        ],
        LegalDocumentType.datenschutz => <_Fact>[
          _Fact(t.legal.document.factCompanyName, config.legalCompanyName),
          _Fact(t.legal.document.factContactEmail, config.legalContactEmail),
          _Fact(
            t.legal.document.factSupervisoryAuthority,
            config.legalSupervisoryAuthority,
          ),
        ],
        LegalDocumentType.agb => <_Fact>[
          _Fact(t.legal.document.factCompanyName, config.legalCompanyName),
          _Fact(t.legal.document.factAddress, config.legalAddress),
        ],
        LegalDocumentType.barrierefreiheit => <_Fact>[
          _Fact(t.legal.document.factCompanyName, config.legalCompanyName),
          _Fact(t.legal.document.factContactEmail, config.legalContactEmail),
        ],
      };

  @override
  Widget build(BuildContext context) {
    final facts = _facts(type, config);

    return AppScreenScaffold(
      title: _title(type),
      contentWidth: AppContentWidth.reading,
      back: AppScreenHeaderBack(
        semanticLabel: t.common.back,
        onPressed: onBack,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          StyledText(t.legal.document.templateNotice, style: captionStyle()),
          const AppGap.v4(),
          StyledText(_intro(type), style: bodyStyle()),
          const AppGap.v2(),
          for (var i = 0; i < facts.length; i++)
            AppFactRow(
              label: facts[i].label,
              value: facts[i].value,
              isFirst: i == 0,
            ),
        ],
      ),
    );
  }
}
