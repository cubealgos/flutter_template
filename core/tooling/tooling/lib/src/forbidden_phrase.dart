/// Folds [text] for German-aware, case-insensitive comparison: lower-cases
/// it (so `Ä`/`ẞ` reach `ä`/`ß`) and spells out `ä`, `ö`, `ü` and `ß` as
/// `ae`, `oe`, `ue` and `ss`, so `Rechtssicher` and `RECHTSSICHER`, or
/// `gestützt` and its transliteration `gestuetzt`, compare equal. Applied
/// to the phrase and the scanned text alike, so it can only widen what
/// matches, never make an identical string stop matching.
String foldGerman(String text) => text
    .toLowerCase()
    .replaceAll('ä', 'ae')
    .replaceAll('ö', 'oe')
    .replaceAll('ü', 'ue')
    .replaceAll('ß', 'ss');

/// Collapses every run of whitespace in [text] to one space and trims it,
/// so a sentence compares the same wherever a line break fell.
String normaliseWhitespace(String text) =>
    text.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Splits [text] into sentences: after `.`, `!` or `?` followed by
/// whitespace, and at line breaks. Empty pieces are dropped and each piece
/// has its whitespace normalised.
List<String> splitSentences(String text) => [
  for (final piece in text.split(RegExp(r'(?<=[.!?])\s+|\n')))
    if (normaliseWhitespace(piece).isNotEmpty) normaliseWhitespace(piece),
];

/// One forbidden phrase, compiled to a word-aware matcher over folded text.
///
/// A phrase matches only as a whole word (or word sequence): the characters
/// on either side must not be a letter (any script, so umlauts and `ß`
/// count), digit or underscore. `barrierefrei` therefore matches
/// "Das ist barrierefrei." but not "Barrierefreiheit" or "unbarrierefrei".
/// A trailing `*` lets the last word carry any letters after it, for
/// German inflections: `barrierefrei*` also matches `barrierefreie`,
/// `barrierefreier` and `Barrierefreiheit`. Spaces in a phrase match any
/// run of whitespace.
class ForbiddenPhrase {
  /// Compiles [text] (as written in the phrase file).
  ForbiddenPhrase(this.text) : _pattern = _compile(text);

  /// The phrase exactly as written in the phrase file.
  final String text;

  final RegExp _pattern;

  /// True if [sentence] contains this phrase as a whole word.
  bool occursIn(String sentence) => _pattern.hasMatch(foldGerman(sentence));

  static RegExp _compile(String text) {
    var folded = foldGerman(normaliseWhitespace(text));
    final inflected = folded.endsWith('*');
    if (inflected) folded = folded.substring(0, folded.length - 1);
    final body = folded.split(' ').map(RegExp.escape).join(r'\s+');
    final tail = inflected ? r'[\p{L}\p{N}_]*' : '';

    return RegExp(
      '(?<![\\p{L}\\p{N}_])$body$tail(?![\\p{L}\\p{N}_])',
      unicode: true,
    );
  }
}
