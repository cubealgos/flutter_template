import 'package:test/test.dart';
import 'package:tooling/src/acceptance_criteria.dart';

void main() {
  test('returns unchecked items only, trimmed', () {
    const body = '''
Some intro text.

## Acceptance criteria
- [ ] first item
- [x] second item, done
- [X] third item, also done (capital X)
- [ ]    fourth item, extra spaces
''';

    expect(uncheckedAcceptanceCriteria(body), <String>[
      'first item',
      'fourth item, extra spaces',
    ]);
  });

  test('returns an empty list when every item is checked', () {
    const body = '''
## Acceptance criteria
- [x] done one
- [X] done two
''';

    expect(uncheckedAcceptanceCriteria(body), isEmpty);
  });

  test('returns an empty list when the section is absent', () {
    const body = '''
## Something else
- [ ] not acceptance criteria
''';

    expect(uncheckedAcceptanceCriteria(body), isEmpty);
  });

  test('stops at the next heading', () {
    const body = '''
## Acceptance criteria
- [ ] in section

## Notes
- [ ] not in section
''';

    expect(uncheckedAcceptanceCriteria(body), <String>['in section']);
  });

  test('matches the heading case-insensitively at any level', () {
    const body = '''
### acceptance CRITERIA
- [ ] item
''';

    expect(uncheckedAcceptanceCriteria(body), <String>['item']);
  });
}
