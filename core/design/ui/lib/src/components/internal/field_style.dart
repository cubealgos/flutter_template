import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:ui/src/tokens.g.dart';
import 'package:ui/src/typography/package_font_family.dart';

/// The minimum logical-pixel hit target on a single-line text input's
/// bordered surface — shared by every field in this package
/// (`AppTextField`, `AppCodeField`).
const double fieldMinHitTarget = 48;

/// The shared chrome-wrapping [NakedTextField.builder] every single-line
/// text input in this package uses: a [WidgetStateProvider] plus the
/// bordered, min-height surface from [fieldBoxStyle].
NakedTextFieldBuilder fieldInputBuilder({required bool hasError}) {
  return (_, state, editableText) => WidgetStateProvider(
    states: state.states,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: fieldMinHitTarget),
      child: Box(
        style: fieldBoxStyle(hasError: hasError),
        child: Center(child: editableText),
      ),
    ),
  );
}

/// The bordered field surface's fill, border, and interaction-state
/// styling, shared by every single-line text input in this package
/// (`AppTextField`, `AppCodeField`). [hasError] overrides the resting
/// border color regardless of interaction state.
BoxStyler fieldBoxStyle({required bool hasError}) {
  final borderColor = hasError ? colorDanger() : colorBorder();

  return BoxStyler()
      .paddingX(space3())
      .paddingY(space2())
      .borderRadiusAll(radiusMd())
      .borderAll(color: borderColor, width: strokeDefault())
      .onHovered(
        BoxStyler().borderAll(color: colorAccent(), width: strokeDefault()),
      )
      .onFocused(
        BoxStyler().borderAll(color: colorFocusRing(), width: strokeStrong()),
      )
      .onDisabled(
        BoxStyler()
            .color(colorBgSubtle())
            .borderAll(color: colorDisabled(), width: strokeDefault()),
      );
}

/// A field's below-input error message typography, shared by every
/// single-line text input in this package.
TextStyler fieldErrorStyle() {
  return TextStyler()
      .fontSize(productBodySm())
      .fontFamily(packageFontFamily(fontFamilyBody))
      .fontFamilyFallback(fontFamilyBodyFallback)
      .color(colorDanger());
}
