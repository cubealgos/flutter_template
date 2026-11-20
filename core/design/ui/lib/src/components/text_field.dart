import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:ui/src/components/internal/field_style.dart';
import 'package:ui/src/components/internal/text_styles.dart';
import 'package:ui/src/tokens.g.dart';
import 'package:ui/src/typography/package_font_family.dart';

/// A headless, mix-styled single-line text field with a visible label and
/// an optional error message.
///
// This file is named for the component's role; the class carries this
// package's `App` prefix, so the two names don't literally match — same
// convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class AppTextField extends StatelessWidget {
  /// Creates an `AppTextField`.
  const AppTextField({
    required this.label,
    super.key,
    this.controller,
    this.errorText,
    this.onChanged,
    this.focusNode,
    this.obscureText = false,
    this.enabled = true,
  });

  /// The visible, and accessible, label shown above the field.
  final String label;

  /// Controls and observes the field's text.
  final TextEditingController? controller;

  /// A validation message shown below the field, and announced alongside
  /// the field's accessible name when set.
  final String? errorText;

  /// Whether to obscure entered text, for passwords and similar fields.
  final bool obscureText;

  /// Called on every text change.
  final ValueChanged<String>? onChanged;

  /// The focus node for this field.
  final FocusNode? focusNode;

  /// Whether the field accepts input at all.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final error = errorText;
    final inputStyle = _inputTextStyle(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The field below already carries `label` as its own accessible
        // name (via `semanticLabel`); excluding this visible copy from the
        // semantics tree avoids announcing it twice.
        ExcludeSemantics(
          child: Box(
            style: BoxStyler().paddingBottom(space1()),
            child: StyledText(label, style: secondaryTextStyle()),
          ),
        ),
        NakedTextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          enabled: enabled,
          error: error != null,
          style: inputStyle,
          semanticLabel: label,
          semanticErrorText: error,
          onChanged: onChanged,
          builder: fieldInputBuilder(hasError: error != null),
        ),
        // Already carried as the field's semantic hint via
        // `semanticErrorText` above; excluded here for the same reason as
        // the label.
        if (error != null)
          ExcludeSemantics(
            child: Box(
              style: BoxStyler().paddingTop(space1()),
              child: StyledText(error, style: fieldErrorStyle()),
            ),
          ),
      ],
    );
  }
}

/// The actual [EditableText]'s [TextStyle], resolved to concrete values —
/// [EditableText] is not mix-aware, so this cannot flow through a
/// [TextStyler] chain the way [StyledText] content does.
TextStyle _inputTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: productBody.resolve(context),
    fontFamily: packageFontFamily(fontFamilyBody),
    fontFamilyFallback: fontFamilyBodyFallback,
    color: colorFg.resolve(context),
  );
}
