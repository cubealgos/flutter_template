import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:ui/src/tokens.g.dart';
import 'package:ui/src/typography/package_font_family.dart';

/// The minimum logical-pixel hit target on the [AppCheckbox] row.
const double _minHitTarget = 48;

/// The checkbox box's fixed square size, in logical pixels.
const double _boxSize = 20;

/// A headless, mix-styled checkbox with a visible label.
///
/// [value] has no default: a pre-checked checkbox is a deliberate choice
/// the caller must make explicitly by passing `value: true`, never an
/// implicit default of this widget.
///
// This file is named for the component's role; the class carries this
// package's `App` prefix, so the two names don't literally match — same
// convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class AppCheckbox extends StatelessWidget {
  /// Creates an `AppCheckbox`.
  const AppCheckbox({
    required this.label,
    required this.value,
    super.key,
    this.onChanged,
    this.enabled = true,
  });

  /// The visible, and accessible, label for this checkbox.
  final String label;

  /// The current checked state. The caller must pass this explicitly.
  final bool value;

  /// Called with the next value when the checkbox is toggled.
  final ValueChanged<bool?>? onChanged;

  /// Whether the checkbox accepts input at all.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return NakedCheckbox(
      value: value,
      onChanged: onChanged,
      enabled: enabled,
      semanticLabel: label,
      builder: (_, state, _) => WidgetStateProvider(
        states: state.states,
        child: _AppCheckboxRow(checked: state.isChecked == true, label: label),
      ),
    );
  }
}

/// The tappable row content: the checkbox square plus its visible label.
class _AppCheckboxRow extends StatelessWidget {
  const _AppCheckboxRow({required this.checked, required this.label});

  final bool checked;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHitTarget),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: _minHitTarget,
              minHeight: _minHitTarget,
            ),
            child: Center(child: _AppCheckboxBox(checked: checked)),
          ),
          Box(
            style: BoxStyler().paddingLeft(space2()),
            child: StyledText(label, style: _labelStyle()),
          ),
        ],
      ),
    );
  }
}

/// The small square that shows the checked/unchecked/focused/disabled
/// state.
class _AppCheckboxBox extends StatelessWidget {
  const _AppCheckboxBox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Box(
      style: _boxStyle(checked: checked),
      child: checked
          ? Center(child: StyledText('✓', style: _markStyle()))
          : null,
    );
  }
}

/// The checkbox square's fill, border, and interaction-state styling.
///
/// [checked] is applied as a direct, Dart-level conditional rather than a
/// mix `WidgetState.selected` variant: naked_ui's `NakedCheckboxState`
/// never adds `WidgetState.selected` to its `states` set (confirmed by
/// reading `naked_checkbox.dart`), so a `.variant(ContextVariant.widgetState
/// (WidgetState.selected), ...)` branch would silently never activate.
BoxStyler _boxStyle({required bool checked}) {
  final base = BoxStyler()
      .size(_boxSize, _boxSize)
      .borderRadiusAll(radiusSm())
      .onFocused(
        BoxStyler().borderAll(color: colorFocusRing(), width: strokeStrong()),
      )
      .onDisabled(
        BoxStyler().borderAll(color: colorDisabled(), width: strokeDefault()),
      );

  if (checked) {
    return base
        .color(colorAccent())
        .borderAll(color: colorAccent(), width: strokeDefault());
  }

  return base
      .borderAll(color: colorBorder(), width: strokeDefault())
      .onHovered(
        BoxStyler().borderAll(color: colorAccent(), width: strokeDefault()),
      );
}

/// The check glyph's styling.
TextStyler _markStyle() {
  return TextStyler().fontSize(productBodySm()).color(colorOnAccent());
}

/// The visible label's typography, composed from `product*` scale tokens
/// per this package's convention (there is no pre-built body-text token).
TextStyler _labelStyle() {
  return TextStyler()
      .fontSize(productBody())
      .fontFamily(packageFontFamily(fontFamilyBody))
      .fontFamilyFallback(fontFamilyBodyFallback)
      .color(colorFg())
      .onDisabled(TextStyler().color(colorDisabled()));
}
