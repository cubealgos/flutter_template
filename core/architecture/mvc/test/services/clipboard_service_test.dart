import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvc/mvc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SystemClipboardService', () {
    const service = SystemClipboardService();

    /// The most recent `Clipboard.setData` call's text, captured from the
    /// mocked `flutter/platform` method channel — the same channel
    /// `Clipboard.setData` sends `"Clipboard.setData"` calls over.
    String? lastCopiedText;

    setUp(() {
      lastCopiedText = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              lastCopiedText = (call.arguments as Map)['text'] as String?;
            }

            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test(
      'copyText sends the text over the platform clipboard channel',
      () async {
        await service.copyText('hello clipboard');

        expect(lastCopiedText, 'hello clipboard');
      },
    );
  });
}
