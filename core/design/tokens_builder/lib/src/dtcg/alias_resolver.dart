import 'package:tokens_builder/src/dtcg/raw_leaf.dart';
import 'package:tokens_builder/src/dtcg/token_build_exception.dart';

final RegExp _aliasPattern = RegExp(r'^\{([A-Za-z0-9_.\-]+)\}$');

/// Resolves every `{a.b.c}` alias reference in [leaves] against the other
/// entries of the same map, following chains of aliases to their concrete
/// value.
///
/// Returns a new map with the same keys, where every leaf's [RawLeaf.value]
/// is concrete (never itself an alias string). A leaf's own `$type` is left
/// untouched — DTCG has every alias re-declare its own `$type`, so this
/// resolver never needs to borrow one from the token it points to.
///
/// Throws [TokenBuildException] naming the full chain on a cycle, and naming
/// the token on a reference to an unknown path.
Map<String, RawLeaf> resolveAliases(Map<String, RawLeaf> leaves) {
  final resolved = <String, RawLeaf>{};
  for (final entry in leaves.entries) {
    resolved[entry.key] = entry.value.withValue(
      _resolveValue(leaves, entry.key, <String>[entry.key]),
    );
  }

  return resolved;
}

Object _resolveValue(
  Map<String, RawLeaf> leaves,
  String path,
  List<String> chain,
) {
  final leaf = leaves[path];
  if (leaf == null) {
    throw TokenBuildException(
      'Token "${chain.first}" references unknown token "$path" '
      '(chain: ${chain.join(' -> ')}).',
    );
  }
  final value = leaf.value;
  if (value is! String) return value;
  final match = _aliasPattern.firstMatch(value);
  if (match == null) return value;

  // Safe: group 1 is a mandatory (non-optional) capture in _aliasPattern —
  // a match can only occur with it populated.
  // ignore: solid_lints/avoid_non_null_assertion
  final target = match.group(1)!;
  if (chain.contains(target)) {
    throw TokenBuildException(
      'Alias cycle: ${[...chain, target].join(' -> ')}.',
    );
  }

  return _resolveValue(leaves, target, [...chain, target]);
}
