import 'package:flutter_test/flutter_test.dart';
import 'package:mvc/mvc.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// A hand-written fake `UrlLauncherPlatform`, standing in for mockito
/// codegen (not wired up yet). Records every call it receives so
/// tests can assert on them, and returns caller-configured results.
//
// File is named after the package (`launcher_service_test.dart`), not after
// this fixture class.
// ignore: solid_lints/prefer_match_file_name
class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  bool canLaunchResult = true;
  bool launchResult = true;

  String? lastCanLaunchUrl;
  String? lastLaunchUrl;
  LaunchOptions? lastLaunchOptions;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async {
    lastCanLaunchUrl = url;

    return canLaunchResult;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchUrl = url;
    lastLaunchOptions = options;

    return launchResult;
  }
}

void main() {
  group('UrlLauncherService', () {
    // A fresh fake per test, assigned in `setUp` — standard test-fixture
    // pattern, no meaningful non-`late` alternative.
    // ignore: solid_lints/avoid_late_keyword
    late _FakeUrlLauncherPlatform fake;
    const service = UrlLauncherService();

    setUp(() {
      fake = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
    });

    test('openUrl delegates to the platform and returns its result', () async {
      fake.launchResult = true;
      final url = Uri.parse('https://example.com');

      final launched = await service.openUrl(url);

      expect(launched, isTrue);
      expect(fake.lastLaunchUrl, url.toString());
    });

    test(
      'openUrl with external:true requests an external application',
      () async {
        final url = Uri.parse('https://example.com');

        await service.openUrl(url, external: true);

        expect(
          fake.lastLaunchOptions?.mode,
          PreferredLaunchMode.externalApplication,
        );
      },
    );

    test('openUrl without external requests the platform default', () async {
      final url = Uri.parse('https://example.com');

      await service.openUrl(url);

      expect(fake.lastLaunchOptions?.mode, PreferredLaunchMode.platformDefault);
    });

    test('openUrl reports a failed launch', () async {
      fake.launchResult = false;

      final launched = await service.openUrl(Uri.parse('https://example.com'));

      expect(launched, isFalse);
    });

    test('canOpen delegates to the platform and returns its result', () async {
      fake.canLaunchResult = false;
      final url = Uri.parse('tel:+1234567890');

      final canOpen = await service.canOpen(url);

      expect(canOpen, isFalse);
      expect(fake.lastCanLaunchUrl, url.toString());
    });
  });
}
