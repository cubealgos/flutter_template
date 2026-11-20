import 'package:app/features/legal/licences/licences_model.dart';
import 'package:app/features/legal/licences/widgets/licence_detail_sheet.dart';
import 'package:app/features/legal/licences/widgets/licences_body.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// The OSS licences page: the list of packages, each opening its licence
/// text in a bottom sheet.
class LicencesMobileLayout extends StatelessWidget {
  /// Creates the layout.
  const LicencesMobileLayout({
    required this.model,
    required this.onBack,
    required this.onCopyLicenceText,
    super.key,
  });

  /// The licences state being rendered.
  final LicencesModel model;

  /// Called when the back chevron is pressed.
  final VoidCallback onBack;

  /// Called with a licence's combined text when its copy button is pressed.
  final ValueChanged<String> onCopyLicenceText;

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: t.legal.licences.title,
      back: AppScreenHeaderBack(
        semanticLabel: t.common.back,
        onPressed: onBack,
      ),
      body: LicencesBody(
        loading: model.loading,
        entries: model.entries,
        onEntryTap: (entry) => showAppSheet<void>(
          context: context,
          semanticLabel: entry.packageName,
          builder: (_) =>
              LicenceDetailSheet(entry: entry, onCopy: onCopyLicenceText),
        ),
      ),
    );
  }
}
