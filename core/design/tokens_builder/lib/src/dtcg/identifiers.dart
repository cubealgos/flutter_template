/// Converts a dot-joined DTCG token path (e.g. `color.paper-2`,
/// `typography.node-name.font-size`) to a camelCase Dart identifier (e.g.
/// `colorPaper2`, `typographyNodeNameFontSize`).
///
/// Splits on both `.` (DTCG group nesting) and `-` (kebab-case key
/// segments), lowercases every segment, and upper-cases only the first
/// *alphabetic* character of every segment after the first — a segment
/// starting with a digit (e.g. `2xl`) is left as-is there, which still
/// yields a valid, readable Dart identifier (`product2xl`).
String pathToIdentifier(String path) {
  final segments = path.split(RegExp(r'[.\-]'));
  final buffer = StringBuffer();
  for (var i = 0; i < segments.length; i++) {
    final segment = segments[i].toLowerCase();
    if (segment.isEmpty) continue;
    buffer.write(i == 0 ? segment : _capitalizeFirstLetter(segment));
  }

  return buffer.toString();
}

String _capitalizeFirstLetter(String segment) {
  final first = segment[0];
  final upper = first.toUpperCase();
  if (upper == first) return segment;

  return upper + segment.substring(1);
}
