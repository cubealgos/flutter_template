import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// The sizes baked into `web/favicon.ico`: 16 (browser tab favicon), 32
/// (taskbar/shortcut icon) and 48 (Windows desktop shortcut) — the
/// conventional multi-size favicon.ico set neither
/// flutter_launcher_icons (which only writes `web/favicon.png`) nor
/// flutter_native_splash generates. See `icons_command.dart`.
const List<int> faviconIcoSizes = <int>[16, 32, 48];

/// The apple-touch-icon size iOS/iPadOS actually requests for a home-screen
/// bookmark (the largest @3x home-screen tile; iOS scales down for smaller
/// devices itself) — see Apple's App Icon human interface guidelines.
/// flutter_launcher_icons does not generate this file at all for web.
const int appleTouchIconSize = 180;

/// The channel count [generateAppleTouchIcon] converts its resized copy to
/// — red, green, blue, no alpha.
const int _rgbChannelCount = 3;

/// Resizes [source] to [size]x[size] using
/// [img.Interpolation.average] — appropriate for every use in this file,
/// since every output here is a downscale from a 1024x1024 source (see
/// `apps/app/assets/icon/README.md`).
img.Image _resizeSquare(img.Image source, int size) => img.copyResize(
  source,
  width: size,
  height: size,
  interpolation: img.Interpolation.average,
);

/// Encodes [source] as a multi-size `favicon.ico` containing one frame per
/// [faviconIcoSizes] entry, each a resized copy of [source]. Pure: takes a
/// decoded image, returns encoded bytes, touches no filesystem — see
/// `icon_image_generation_test.dart` for in-process assertions on the
/// decoded frame sizes.
Uint8List generateFaviconIco(img.Image source) {
  final frames = faviconIcoSizes
      .map((size) => _resizeSquare(source, size))
      .toList(growable: false);

  return img.IcoEncoder().encodeImages(frames);
}

/// Encodes [source] as a [appleTouchIconSize]x[appleTouchIconSize] PNG with
/// no alpha channel, for `web/apple-touch-icon.png`. No alpha because
/// Safari's "Add to Home Screen" renders a transparent apple-touch-icon on
/// a black tile rather than compositing it — the icon is expected to be
/// fully opaque, matching `assets/icon/icon.png`'s own requirement (see
/// that directory's README.md).
Uint8List generateAppleTouchIcon(img.Image source) {
  final resized = _resizeSquare(source, appleTouchIconSize);
  final opaque = resized.convert(numChannels: _rgbChannelCount);

  return img.encodePng(opaque);
}

/// Encodes [source] as a [size]x[size] PNG for the Linux launcher icon —
/// both the `share/icons/hicolor/<size>x<size>/apps/` theme install
/// (`linux/CMakeLists.txt`) and, at [size] 256, the window icon
/// `my_application.cc` loads at runtime.
Uint8List generateLinuxIconPng(img.Image source, {required int size}) =>
    img.encodePng(_resizeSquare(source, size));
