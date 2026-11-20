import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mocks the `path_provider` channel the Appwrite client SDK asks for its
/// cookie directory, answering with a throwaway temp directory named after
/// [tempPrefix] (removed when the test run ends). Shared by this package's
/// integration suites.
void initPathProviderChannel(String tempPrefix) {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        if (call.method != 'getApplicationDocumentsDirectory') return null;
        final dir = await Directory.systemTemp.createTemp(tempPrefix);
        addTearDown(() => dir.deleteSync(recursive: true));

        return dir.path;
      });
}
