import 'package:api/src/actions/review_demo_sign_in/constant_time_equals.dart';
import 'package:test/test.dart';

void main() {
  test('true for identical strings', () {
    expect(constantTimeEquals('the-review-code', 'the-review-code'), isTrue);
  });

  test('false for a same-length mismatch', () {
    expect(constantTimeEquals('the-review-code', 'the-review-cod3'), isFalse);
  });

  test('false for different lengths', () {
    expect(constantTimeEquals('short', 'much-longer'), isFalse);
  });

  test('false comparing against an empty string', () {
    expect(constantTimeEquals('', 'the-review-code'), isFalse);
  });

  test('true comparing two empty strings', () {
    expect(constantTimeEquals('', ''), isTrue);
  });
}
