import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/src/layout/breakpoints.dart';

void main() {
  group('Breakpoint re-export matches spec.md §1.1', () {
    test('mobile is anything narrower than 768px', () {
      expect(Breakpoint.mobile.matches(const Size(767, 800)), isTrue);
      expect(Breakpoint.mobile.matches(const Size(768, 800)), isFalse);
    });

    test('tablet is 768–1023px', () {
      expect(Breakpoint.tablet.matches(const Size(768, 800)), isTrue);
      expect(Breakpoint.tablet.matches(const Size(1023, 800)), isTrue);
      expect(Breakpoint.tablet.matches(const Size(1024, 800)), isFalse);
    });

    test('desktop is 1024px and up', () {
      expect(Breakpoint.desktop.matches(const Size(1024, 800)), isTrue);
      expect(Breakpoint.desktop.matches(const Size(1023, 800)), isFalse);
    });
  });
}
