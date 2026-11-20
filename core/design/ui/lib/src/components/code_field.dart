import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:ui/src/components/internal/field_style.dart';
import 'package:ui/src/components/internal/text_styles.dart';
import 'package:ui/src/tokens.g.dart';
import 'package:ui/src/typography/package_font_family.dart';

/// The default number of digits an [AppCodeField] accepts — the app's
/// sign-in and privacy-export one-time codes are both 6 digits (spec.md
/// §2.3, §2.11).
const int _defaultLength = 6;

/// [productMonoData]'s own font size, in logical pixels — see
/// `text_styles.dart`'s `_eyebrowFontSizePx` for why this is duplicated
/// as a literal rather than resolved from the token at const-evaluation
/// time. Keep in sync with `tokens/typography.json`'s `product.mono-data`
/// value.
const double _monoDataFontSizePx = 16;

/// `letter-spacing: 0.12em`, matching the mockups' `.mono-input`.
const double _trackingEm = 0.12;

/// `mono-data`'s letter-spacing for a code field, matching the mockups'
/// `.mono-input`. A `TextStyle`'s `letterSpacing` is absolute logical
/// pixels, not font-relative `em` — same reasoning as `eyebrowStyle()`'s
/// tracking — so this pre-multiplies [_trackingEm] against
/// [_monoDataFontSizePx].
const double _codeLetterSpacing = _monoDataFontSizePx * _trackingEm;

/// A single-field, `mono-data`-styled one-time-code input — the sign-in
/// code and the privacy-export step-up code (spec.md §2.3, §2.11).
///
/// Deliberately **one field**, not six boxes: a single field keeps SMS/App
/// autofill, screen-reader semantics, paste, and undo, all of which a
/// six-box implementation routinely loses (see `tokens-needed.md` §B's
/// evidence). Wires [AutofillHints.oneTimeCode] — Flutter's equivalent of
/// the web's `autocomplete="one-time-code"` — and restricts input to
/// digits via a [FilteringTextInputFormatter], which `AppTextField` does
/// not do (it is a general-purpose text field with no digit-only or
/// autofill-hint concept).
///
// This file is named for the component's role; the class carries this
// package's `App` prefix, so the two names don't literally match — same
// convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class AppCodeField extends StatelessWidget {
  /// Creates an `AppCodeField`.
  const AppCodeField({
    required this.label,
    super.key,
    this.controller,
    this.errorText,
    this.onChanged,
    this.focusNode,
    this.enabled = true,
    this.length = _defaultLength,
  });

  /// The visible, and accessible, label shown above the field.
  final String label;

  /// Controls and observes the field's text.
  final TextEditingController? controller;

  /// A validation message shown below the field, and announced alongside
  /// the field's accessible name when set.
  final String? errorText;

  /// Called on every text change.
  final ValueChanged<String>? onChanged;

  /// The focus node for this field.
  final FocusNode? focusNode;

  /// Whether the field accepts input at all.
  final bool enabled;

  /// The expected code length — enforced as a hard `maxLength`, not just
  /// a hint. Defaults to 6 (this template's OTP length).
  final int length;

  @override
  Widget build(BuildContext context) {
    final error = errorText;

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
          enabled: enabled,
          error: error != null,
          style: _inputTextStyle(context),
          semanticLabel: label,
          semanticErrorText: error,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          maxLength: length,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
/// [TextStyler] chain the way [StyledText] content does. `mono-data`
/// styling, tracked per [_codeLetterSpacing].
TextStyle _inputTextStyle(BuildContext context) {
  return TextStyle(
    fontSize: productMonoData.resolve(context),
    fontFamily: packageFontFamily(fontFamilyMono),
    fontFamilyFallback: fontFamilyMonoFallback,
    letterSpacing: _codeLetterSpacing,
    color: colorFg.resolve(context),
  );
}
