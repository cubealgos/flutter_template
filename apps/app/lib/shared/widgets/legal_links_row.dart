import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// The Terms & Conditions / Privacy Policy footer links (plus an optional
/// leading "Legal" link) shown under sign-in and the paywall. Plain
/// underlined text links in a wrapping row, not bordered buttons (spec.md
/// §2.3/§3: three bordered secondary buttons in one row is a real overflow
/// risk at 390px and reads far heavier than a footer should).
class LegalLinksRow extends StatelessWidget {
  /// Creates the row. The "Legal" link is only shown when [onOpenLegal] is
  /// given.
  const LegalLinksRow({
    required this.onOpenAgb,
    required this.onOpenDatenschutz,
    super.key,
    this.onOpenLegal,
  });

  /// Called when the user taps "Terms & Conditions" (AGB).
  final VoidCallback onOpenAgb;

  /// Called when the user taps "Privacy Policy" (Datenschutz).
  final VoidCallback onOpenDatenschutz;

  /// Called when the user taps "Legal"; the link is omitted when `null`.
  final VoidCallback? onOpenLegal;

  @override
  Widget build(BuildContext context) {
    final onOpenLegal = this.onOpenLegal;

    return AppLinkRow(
      links: <AppTextLinkButton>[
        if (onOpenLegal != null)
          AppTextLinkButton(label: t.common.legalLink, onPressed: onOpenLegal),
        AppTextLinkButton(label: t.common.agbLink, onPressed: onOpenAgb),
        AppTextLinkButton(
          label: t.common.datenschutzLink,
          onPressed: onOpenDatenschutz,
        ),
      ],
    );
  }
}
