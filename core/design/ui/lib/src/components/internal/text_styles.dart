import 'package:mix/mix.dart';
import 'package:ui/src/tokens.g.dart';
import 'package:ui/src/typography/text_styles.dart';

/// The secondary/muted small-body typography shared by a field's label
/// (`AppTextField`) and a list row's subtitle (`AppListTile`) — both are
/// "supporting text below or beside the primary content". The muted
/// variant of the public `bodySmStyle()` role (spec §1.2's `body-sm`,
/// which itself resolves to `colorInk` — see that function's dartdoc).
TextStyler secondaryTextStyle() {
  return bodySmStyle().color(colorFgSubtle());
}
