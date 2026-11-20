import 'package:app/features/legal/licences/licence_group.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// The content of a licence's detail sheet: the package name, its full
/// licence text(s) — a package named by more than one `LicenseEntry` shows
/// each text, divided — and a copy button.
class LicenceDetailSheet extends StatelessWidget {
  /// Creates the sheet content for [entry].
  const LicenceDetailSheet({
    required this.entry,
    required this.onCopy,
    super.key,
  });

  /// The maximum height of the full licence text's scroll region — long
  /// enough to read comfortably, short enough that the sheet itself never
  /// grows taller than the screen (spec.md §2.10: a licence's full text can
  /// run to hundreds of lines).
  static const double _detailMaxHeight = 360;

  /// The licence group being shown.
  final LicenceGroup entry;

  /// Called with the combined licence text when the copy button is pressed.
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    final combinedText = entry.texts.join('\n\n');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        StyledText(entry.packageName, style: h3Style()),
        const AppGap.v3(),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: _detailMaxHeight),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (var i = 0; i < entry.texts.length; i++) ...<Widget>[
                  if (i > 0) ...<Widget>[
                    const AppGap.v3(),
                    const AppDivider(),
                    const AppGap.v3(),
                  ],
                  AppCodeBlock(text: entry.texts[i]),
                ],
              ],
            ),
          ),
        ),
        const AppGap.v3(),
        AppButton(
          semanticLabel: t.legal.licences.copyButton,
          onPressed: () => onCopy(combinedText),
          variant: AppButtonVariant.secondary,
          child: Text(t.legal.licences.copyButton),
        ),
      ],
    );
  }
}
