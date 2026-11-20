import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/src/tokens.g.dart';

/// A fixed empty gap whose extent is one of the `space.*` design tokens.
///
/// Use it instead of a hand-built spacer box: `AppGap.v4()` is a vertical
/// gap of `space4` (it takes up height), `AppGap.h4()` a horizontal one (it
/// takes up width). Every `space*` token has a `v<N>` and an `h<N>` form; the
/// size is read from the token, so it follows the theme.
///
// This file is named for the layout role; the class carries this package's
// `App` prefix, so the two names don't literally match — same convention as
// `AppDivider`.
// ignore: solid_lints/prefer_match_file_name
class AppGap extends StatelessWidget {
  const AppGap._(this._token, this._axis, {super.key});

  /// A vertical gap of `space1`.
  const AppGap.v1({Key? key}) : this._(space1, Axis.vertical, key: key);

  /// A vertical gap of `space2`.
  const AppGap.v2({Key? key}) : this._(space2, Axis.vertical, key: key);

  /// A vertical gap of `space3`.
  const AppGap.v3({Key? key}) : this._(space3, Axis.vertical, key: key);

  /// A vertical gap of `space4`.
  const AppGap.v4({Key? key}) : this._(space4, Axis.vertical, key: key);

  /// A vertical gap of `space6`.
  const AppGap.v6({Key? key}) : this._(space6, Axis.vertical, key: key);

  /// A vertical gap of `space8`.
  const AppGap.v8({Key? key}) : this._(space8, Axis.vertical, key: key);

  /// A vertical gap of `space12`.
  const AppGap.v12({Key? key}) : this._(space12, Axis.vertical, key: key);

  /// A vertical gap of `space16`.
  const AppGap.v16({Key? key}) : this._(space16, Axis.vertical, key: key);

  /// A vertical gap of `space24`.
  const AppGap.v24({Key? key}) : this._(space24, Axis.vertical, key: key);

  /// A horizontal gap of `space1`.
  const AppGap.h1({Key? key}) : this._(space1, Axis.horizontal, key: key);

  /// A horizontal gap of `space2`.
  const AppGap.h2({Key? key}) : this._(space2, Axis.horizontal, key: key);

  /// A horizontal gap of `space3`.
  const AppGap.h3({Key? key}) : this._(space3, Axis.horizontal, key: key);

  /// A horizontal gap of `space4`.
  const AppGap.h4({Key? key}) : this._(space4, Axis.horizontal, key: key);

  /// A horizontal gap of `space6`.
  const AppGap.h6({Key? key}) : this._(space6, Axis.horizontal, key: key);

  /// A horizontal gap of `space8`.
  const AppGap.h8({Key? key}) : this._(space8, Axis.horizontal, key: key);

  /// A horizontal gap of `space12`.
  const AppGap.h12({Key? key}) : this._(space12, Axis.horizontal, key: key);

  /// A horizontal gap of `space16`.
  const AppGap.h16({Key? key}) : this._(space16, Axis.horizontal, key: key);

  /// A horizontal gap of `space24`.
  const AppGap.h24({Key? key}) : this._(space24, Axis.horizontal, key: key);

  final SpaceToken _token;
  final Axis _axis;

  @override
  Widget build(BuildContext context) {
    final style = BoxStyler();

    return Box(
      style: _axis == Axis.vertical
          ? style.height(_token())
          : style.width(_token()),
    );
  }
}
