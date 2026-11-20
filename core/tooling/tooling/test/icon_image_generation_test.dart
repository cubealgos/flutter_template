import 'package:image/image.dart' as img;
import 'package:test/test.dart';
import 'package:tooling/src/icon_image_generation.dart';
import 'package:tooling/src/icons_command.dart' show linuxIconSizes;

/// Dimensions and colour for [_sourceIcon] — arbitrary, since every
/// function under test only resizes and re-encodes; named so neither is a
/// bare literal at the call site.
const int _sourceIconSize = 256;
const int _sourceColorRed = 29;
const int _sourceColorGreen = 111;
const int _sourceColorBlue = 224;

/// A minimal opaque source image standing in for `assets/icon/icon.png`
/// (1024x1024 in the real app — [_sourceIconSize] keeps these in-process
/// tests fast).
img.Image _sourceIcon() => img.Image(
  width: _sourceIconSize,
  height: _sourceIconSize,
)..clear(img.ColorRgb8(_sourceColorRed, _sourceColorGreen, _sourceColorBlue));

void main() {
  group('generateFaviconIco', () {
    test('encodes one frame per faviconIcoSizes entry, at the right size', () {
      final ico = generateFaviconIco(_sourceIcon());

      final decoded = img.IcoDecoder().decode(ico);
      if (decoded == null) {
        fail('favicon.ico must decode as ICO');
      }
      final frameSizes = decoded.frames.map((frame) => frame.width).toList()
        ..sort();
      final expectedSizes = [...faviconIcoSizes]..sort();
      expect(frameSizes, expectedSizes);
      for (final frame in decoded.frames) {
        expect(frame.width, frame.height, reason: 'every frame is square');
      }
    });
  });

  group('generateAppleTouchIcon', () {
    test('encodes a 180x180 PNG with no alpha channel', () {
      final png = generateAppleTouchIcon(_sourceIcon());

      final decoded = img.decodePng(png);
      if (decoded == null) {
        fail('apple-touch-icon.png must decode as PNG');
      }
      expect(decoded.width, appleTouchIconSize);
      expect(decoded.height, appleTouchIconSize);
      expect(
        decoded.hasAlpha,
        isFalse,
        reason:
            'a transparent apple-touch-icon renders on a black tile in '
            "Safari's Add to Home Screen UI",
      );
    });
  });

  group('generateLinuxIconPng', () {
    for (final size in linuxIconSizes) {
      test('encodes a $size x $size PNG', () {
        final png = generateLinuxIconPng(_sourceIcon(), size: size);

        final decoded = img.decodePng(png);
        if (decoded == null) {
          fail('Linux icon PNG at size $size must decode as PNG');
        }
        expect(decoded.width, size);
        expect(decoded.height, size);
      });
    }
  });
}
