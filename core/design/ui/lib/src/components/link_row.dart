import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/src/components/text_link_button.dart';
import 'package:ui/src/tokens.g.dart';
import 'package:ui/src/typography/text_styles.dart';

/// A centred row of [AppTextLinkButton]s separated by middle dots —
/// `Legal · Terms & Conditions · Privacy Policy` — wrapping onto further
/// lines only when too narrow.
///
// File named for the role; the class carries the package's `App` prefix.
// ignore: solid_lints/prefer_match_file_name
class AppLinkRow extends StatelessWidget {
  /// Creates an `AppLinkRow`.
  const AppLinkRow({required this.links, super.key});

  /// The links, in reading order.
  final List<AppTextLinkButton> links;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        for (final (index, link) in links.indexed) ...<Widget>[
          if (index > 0) const _Separator(),
          link,
        ],
      ],
    );
  }
}

/// The middle dot between two links.
class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Box(
      style: BoxStyler().paddingX(space2()),
      child: StyledText('·', style: bodySmStyle().color(colorFgSubtle())),
    );
  }
}
