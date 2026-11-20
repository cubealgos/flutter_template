import 'package:test/test.dart';
import 'package:tokens_builder/src/dtcg/token_build_exception.dart';

/// A token file that must fail the build, and the strings the error message
/// has to carry (the token path and what was wrong with it).
typedef BuildErrorCase = ({
  String description,
  String tokenJson,
  List<String> mentions,
});

/// The `number` and unknown-`$type` failures both pipelines (Dart and CSS)
/// share, so each pipeline's test loops over the same table.
const List<BuildErrorCase> buildErrorCases = [
  (
    description: 'a number given as a string is a build error, not a number',
    tokenJson: r'{"lh": {"$type": "number", "$value": "1.5"}}',
    mentions: ['"lh"', 'number'],
  ),
  (
    description: r'an unknown $type is still a build error naming the token',
    tokenJson: r'{"gap": {"$type": "gradient", "$value": "x"}}',
    mentions: ['"gap"', 'gradient'],
  ),
];

/// Expects [build] to throw a [TokenBuildException] whose message contains
/// every string in [mentions].
void expectBuildError(void Function() build, List<String> mentions) {
  expect(
    build,
    throwsA(
      isA<TokenBuildException>().having(
        (e) => e.message,
        'message',
        allOf([for (final mention in mentions) contains(mention)]),
      ),
    ),
  );
}
