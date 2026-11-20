import 'package:app/features/legal/legal_hub_model.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// The Legal hub: a tappable list to each legal document.
class LegalHubMobileLayout extends StatelessWidget {
  /// Creates the layout.
  const LegalHubMobileLayout({
    required this.model,
    required this.onBack,
    required this.onOpenImpressum,
    required this.onOpenDatenschutz,
    required this.onOpenAgb,
    required this.onOpenBarrierefreiheit,
    required this.onOpenLicences,
    super.key,
  });

  /// The hub state being rendered.
  final LegalHubModel model;

  /// Called when the back chevron is pressed.
  final VoidCallback onBack;

  /// Called when the Impressum row is tapped.
  final VoidCallback onOpenImpressum;

  /// Called when the Datenschutz row is tapped.
  final VoidCallback onOpenDatenschutz;

  /// Called when the AGB row is tapped.
  final VoidCallback onOpenAgb;

  /// Called when the Barrierefreiheit row is tapped.
  final VoidCallback onOpenBarrierefreiheit;

  /// Called when the licences row is tapped.
  final VoidCallback onOpenLicences;

  @override
  Widget build(BuildContext context) {
    const chevron = AppChevronIcon(
      direction: AppChevronDirection.end,
      color: colorFgSubtle,
    );

    return AppScreenScaffold(
      title: t.legal.title,
      back: AppScreenHeaderBack(
        semanticLabel: t.common.back,
        onPressed: onBack,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppListTile(
            title: t.legal.impressum,
            trailing: chevron,
            onTap: onOpenImpressum,
          ),
          AppListTile(
            title: t.legal.datenschutz,
            trailing: chevron,
            onTap: onOpenDatenschutz,
          ),
          AppListTile(title: t.legal.agb, trailing: chevron, onTap: onOpenAgb),
          if (model.showAccessibilityStatement)
            AppListTile(
              title: t.legal.barrierefreiheit,
              trailing: chevron,
              onTap: onOpenBarrierefreiheit,
            ),
          AppListTile(
            title: t.legal.licencesLink,
            trailing: chevron,
            onTap: onOpenLicences,
          ),
        ],
      ),
    );
  }
}
