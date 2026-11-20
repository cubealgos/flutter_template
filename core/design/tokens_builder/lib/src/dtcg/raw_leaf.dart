/// A single DTCG leaf token as read from JSON, before alias resolution or
/// unit conversion: just its declared (or inherited) `$type`, its raw
/// `$value` (a [String], [num], or [List]), and an optional `$description`.
class RawLeaf {
  /// Creates a raw, unresolved DTCG token leaf.
  const RawLeaf({required this.type, required this.value, this.description});

  /// The token's DTCG `$type` (own, or inherited from an ancestor group).
  final String type;

  /// The token's raw `$value` — a `String` (possibly an alias reference or a
  /// unit-suffixed dimension), a `num` (a bare font-weight), or a `List`
  /// (a `fontFamily` array or a `cubicBezier` array). Never `null` — a DTCG
  /// token with a JSON `null` `$value` is rejected while flattening (see
  /// `flattenTokenTree`), so every consumer downstream can rely on this
  /// being non-nullable instead of asserting it with `!`.
  final Object value;

  /// The token's own `$description`, if it declared one.
  final String? description;

  /// Returns a copy of this leaf with [value] replaced.
  RawLeaf withValue(Object value) =>
      RawLeaf(type: type, value: value, description: description);
}
