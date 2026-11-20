import 'package:test/test.dart';
import 'package:tooling/src/forbidden_phrase.dart';

/// One matching expectation: whether `phrase` occurs in `text`.
typedef _Case = ({String phrase, String text, bool matches});

const List<_Case> _cases = <_Case>[
  // Whole word, case-insensitive.
  (phrase: 'barrierefrei', text: 'Das ist barrierefrei.', matches: true),
  (phrase: 'barrierefrei', text: 'Das ist BARRIEREFREI!', matches: true),
  (phrase: 'barrierefrei', text: 'Barrierefrei', matches: true),
  // Not inside a longer word.
  (phrase: 'barrierefrei', text: 'Barrierefreiheit zählt.', matches: false),
  (phrase: 'barrierefrei', text: 'Die barrierefreie Seite', matches: false),
  (phrase: 'barrierefrei', text: 'unbarrierefrei', matches: false),
  // The longer phrase does not match the shorter word, but matches itself.
  (phrase: 'Barrierefreiheit', text: 'barrierefrei', matches: false),
  (phrase: 'Barrierefreiheit', text: 'Die Barrierefreiheit.', matches: true),
  // A trailing * allows German inflection endings.
  (phrase: 'barrierefrei*', text: 'Die barrierefreie Seite', matches: true),
  (phrase: 'barrierefrei*', text: 'Barrierefreiheit', matches: true),
  (phrase: 'barrierefrei*', text: 'barrierefrei', matches: true),
  (phrase: 'barrierefrei*', text: 'nicht barrier', matches: false),
  // Umlauts and ß, either case, also transliterated.
  (phrase: 'KI-gestützt', text: 'Alles ist KI-GESTÜTZT.', matches: true),
  (phrase: 'KI-gestützt', text: 'ki-gestuetzt', matches: true),
  (phrase: 'Maßnahme', text: 'Eine MASSNAHME.', matches: true),
  (phrase: 'Maßnahme', text: 'Maßnahmen', matches: false),
  (phrase: 'über', text: 'Das ist ÜBER alles', matches: true),
  (phrase: 'über', text: 'Überführung', matches: false),
  (phrase: 'süß', text: 'süßer', matches: false),
  // Multi-word and hyphenated phrases.
  (phrase: '100 % sicher', text: 'Wir sind 100  %\nsicher.', matches: true),
  (phrase: 'BFSG-konform', text: 'Wir sind BFSG-konform.', matches: true),
  (phrase: 'BFSG-konform', text: 'Wir sind BFSG konform.', matches: false),
  // Regex metacharacters are literal.
  (phrase: '100%.', text: '100%x', matches: false),
  (phrase: 'c++', text: 'Wir nutzen c++ hier', matches: true),
];

void main() {
  group('ForbiddenPhrase', () {
    for (final c in _cases) {
      test('"${c.phrase}" ${c.matches ? 'matches' : 'does not match'} '
          '"${c.text}"', () {
        expect(ForbiddenPhrase(c.phrase).occursIn(c.text), c.matches);
      });
    }
  });

  group('splitSentences', () {
    test('splits after sentence punctuation and at line breaks', () {
      expect(splitSentences('Eins. Zwei!  Drei?\nVier'), [
        'Eins.',
        'Zwei!',
        'Drei?',
        'Vier',
      ]);
    });
  });
}
