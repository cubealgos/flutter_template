import 'package:tokens_builder/src/dtcg/raw_leaf.dart';
import 'package:tokens_builder/src/dtcg/token_build_exception.dart';

/// The result of flattening one or more DTCG JSON trees: every leaf token,
/// keyed by its dot-joined path, plus every group's own `$description`
/// (keyed by the group's dot-joined path) — the latter is what a composite
/// `typography.*` entry's summary dartdoc comes from.
///
// This file's name describes the whole flatten/merge pass, not this one
// result type — same convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class FlattenResult {
  /// Creates a flatten result.
  const FlattenResult({required this.leaves, required this.groupDescriptions});

  /// Every leaf token (a node with a `$value`), by dot-joined path.
  final Map<String, RawLeaf> leaves;

  /// Every group's own `$description` (a node without a `$value` that still
  /// carries one), by dot-joined path.
  final Map<String, String> groupDescriptions;
}

/// Deep-merges DTCG JSON trees [a] and [b].
///
/// Groups (object nodes without `$value`) are merged key-by-key. A leaf
/// (a node with `$value`) that exists identically on both sides is kept as
/// one entry; one that exists with *different* content on both sides is a
/// [TokenBuildException] — this is what catches two token files silently
/// redefining the same token path, e.g. `motion.json` and
/// `semantic.motion.json` both declaring a `motion.*` group.
Map<String, dynamic> deepMergeTokenTrees(
  Map<String, dynamic> a,
  Map<String, dynamic> b, {
  String path = '',
}) {
  final merged = Map<String, dynamic>.of(a);
  for (final entry in b.entries) {
    final childPath = path.isEmpty ? entry.key : '$path.${entry.key}';
    merged[entry.key] = _mergeValue(merged[entry.key], entry.value, childPath);
  }

  return merged;
}

Object? _mergeValue(Object? existing, Object? incoming, String path) {
  if (existing == null) return incoming;
  if (existing is Map<String, dynamic> && incoming is Map<String, dynamic>) {
    return deepMergeTokenTrees(existing, incoming, path: path);
  }
  if (_deepEquals(existing, incoming)) return existing;
  throw TokenBuildException(
    'Token "$path" is defined with conflicting content in more than one '
    'token file.',
  );
}

bool _deepEquals(Object? a, Object? b) {
  if (a is Map && b is Map) return _mapsEqual(a, b);
  if (a is List && b is List) return _listsEqual(a, b);

  return a == b;
}

bool _mapsEqual(Map<Object?, Object?> a, Map<Object?, Object?> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
  }

  return true;
}

bool _listsEqual(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_deepEquals(a[i], b[i])) return false;
  }

  return true;
}

/// Flattens a merged DTCG JSON [tree] into leaf tokens and group
/// descriptions, applying `$type` inheritance from ancestor groups.
FlattenResult flattenTokenTree(Map<String, dynamic> tree) {
  final context = _FlattenContext();
  _walk(tree, '', null, context);

  return FlattenResult(
    leaves: context.leaves,
    groupDescriptions: context.groupDescriptions,
  );
}

/// The mutable, accumulated output of a [_walk] pass — bundled into one
/// object so `_walk` itself stays within the 4-parameter limit.
class _FlattenContext {
  final Map<String, RawLeaf> leaves = {};
  final Map<String, String> groupDescriptions = {};
}

void _walk(
  Map<String, dynamic> node,
  String path,
  String? inheritedType,
  _FlattenContext context,
) {
  if (node.containsKey(r'$value')) {
    _walkLeaf(node, path, inheritedType, context);

    return;
  }
  final ownType = (node[r'$type'] as String?) ?? inheritedType;
  final description = node[r'$description'] as String?;
  if (description != null && path.isNotEmpty) {
    context.groupDescriptions[path] = description;
  }
  for (final entry in node.entries) {
    if (entry.key.startsWith(r'$')) continue;
    final childPath = path.isEmpty ? entry.key : '$path.${entry.key}';
    _walk(entry.value as Map<String, dynamic>, childPath, ownType, context);
  }
}

void _walkLeaf(
  Map<String, dynamic> node,
  String path,
  String? inheritedType,
  _FlattenContext context,
) {
  final type = (node[r'$type'] as String?) ?? inheritedType;
  if (type == null) {
    throw TokenBuildException(
      'Token "$path" has no \$type (own or inherited).',
    );
  }
  final value = node[r'$value'] as Object?;
  if (value == null) {
    throw TokenBuildException('Token "$path" has a null \$value.');
  }
  context.leaves[path] = RawLeaf(
    type: type,
    value: value,
    description: node[r'$description'] as String?,
  );
}
