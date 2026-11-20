import 'package:tokens_builder/src/dtcg/identifiers.dart';
import 'package:tokens_builder/src/dtcg/raw_leaf.dart';
import 'package:tokens_builder/src/dtcg/token_build_exception.dart';
import 'package:tokens_builder/src/dtcg/unit_conversion.dart';
import 'package:tokens_builder/src/model/resolved_token.dart';

/// Finds every composite `typography.*` group in [leaves] (any group whose
/// direct children include a `font-size` leaf) and builds one
/// `TextStyleToken` declaration per group, combining `font-size`,
/// `font-weight`, `letter-spacing`, and `font-style`.
///
/// `letter-spacing` in `em` is resolved relative to the same group's own
/// `font-size` — see [resolveDimensionValue] — since that is the only place
/// this token set gives `em` a well-defined base.
CompositeTypographyResult extractCompositeTypography(
  Map<String, String> groupDescriptions,
  Map<String, RawLeaf> leaves,
) {
  final parents = <String>{};
  for (final path in leaves.keys) {
    if (path.endsWith('.font-size')) {
      parents.add(path.substring(0, path.length - '.font-size'.length));
    }
  }

  final tokens = <ResolvedScalarToken>[];
  final consumed = <String>{};
  for (final parent in parents) {
    final builder = _CompositeEntryBuilder(parent, leaves, groupDescriptions);
    tokens.add(builder.build());
    consumed.addAll(builder.consumedPaths);
  }

  return CompositeTypographyResult(tokens: tokens, consumedPaths: consumed);
}

/// Builds one composite `TextStyleToken` declaration for a single
/// `typography.*` group, tracking which of its child leaves it absorbed.
///
// This file's name describes the whole extraction pass, not this single
// helper — same convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class _CompositeEntryBuilder {
  _CompositeEntryBuilder(this.parent, this.leaves, this.groupDescriptions);

  final String parent;
  final Map<String, RawLeaf> leaves;
  final Map<String, String> groupDescriptions;
  final Set<String> consumedPaths = {};
  final List<String> _fields = [];

  /// Builds this entry's `TextStyleToken` declaration. Call at most once —
  /// each builder instance is single-use, scoped to one composite group.
  ResolvedScalarToken build() {
    final fontSizePx = _fontSizePx();
    _fields.add('fontSize: $fontSizePx');
    _addFontWeight();
    _addLetterSpacing(fontSizePx);
    _addFontStyle();

    return ResolvedScalarToken(
      path: parent,
      identifier: pathToIdentifier(parent),
      kind: ScalarTokenKind.textStyle,
      valueSource: 'TextStyle(${_fields.join(', ')})',
      doc: groupDescriptions[parent],
    );
  }

  double _fontSizePx() {
    final path = '$parent.font-size';
    final leaf = leaves[path];
    if (leaf == null) {
      throw TokenBuildException(
        'Token "$path" is missing its own font-size leaf.',
      );
    }
    consumedPaths.add(path);

    return resolveDimensionValue(leaf.value as String, tokenPath: path);
  }

  void _addFontWeight() {
    final path = '$parent.font-weight';
    final leaf = leaves[path];
    if (leaf == null) return;
    consumedPaths.add(path);
    final name = resolveFontWeightConstantName(
      leaf.value as num,
      tokenPath: path,
    );
    _fields.add('fontWeight: FontWeight.$name');
  }

  void _addLetterSpacing(double fontSizePx) {
    final path = '$parent.letter-spacing';
    final leaf = leaves[path];
    if (leaf == null) return;
    consumedPaths.add(path);
    final value = resolveDimensionValue(
      leaf.value as String,
      tokenPath: path,
      emBasisPx: fontSizePx,
    );
    _fields.add('letterSpacing: $value');
  }

  void _addFontStyle() {
    final path = '$parent.font-style';
    final leaf = leaves[path];
    if (leaf == null) return;
    consumedPaths.add(path);
    final raw = leaf.value as String;
    _fields.add(
      'fontStyle: FontStyle.${raw == 'italic' ? 'italic' : 'normal'}',
    );
  }
}
