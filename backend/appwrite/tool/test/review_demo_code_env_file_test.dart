import 'dart:io';

import 'package:appwrite_tool/src/review_demo_account.dart';
import 'package:appwrite_tool/src/review_demo_code_env_file.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'fakes/fake_review_demo_account_gateway.dart';

void main() {
  File newEnvFile() {
    final dir = Directory.systemTemp.createTempSync('env_file_test');
    addTearDown(() => dir.deleteSync(recursive: true));

    return File(p.join(dir.path, '.env.local'));
  }

  test('--rotate with a set variable writes a new code', () async {
    final gateway = FakeReviewDemoAccountGateway()
      ..seedFunctionVariable(
        functionId: reviewDemoFunctionId,
        key: reviewDemoCodeVariableKey,
        value: 'old-code',
      );

    final result = await seedReviewDemoAccount(
      gateway: gateway,
      email: 'reviewer@example.com',
      generateCode: () => 'new-code',
      rotate: true,
    );

    expect(result.generatedCode, 'new-code');
    expect(
      gateway.functionVariable(
        functionId: reviewDemoFunctionId,
        key: reviewDemoCodeVariableKey,
      ),
      'new-code',
    );
  });

  test('--rotate replaces a non-blank line in place, no duplicate', () {
    final envFile = newEnvFile()
      ..writeAsStringSync('A=1\nREVIEW_DEMO_CODE=old\nB=2\n');

    final changed = writeReviewDemoCode(envFile, 'new', overwrite: true);

    expect(changed, isTrue);
    expect(envFile.readAsStringSync(), 'A=1\nREVIEW_DEMO_CODE=new\nB=2\n');
  });

  test('default fills a blank REVIEW_DEMO_CODE line', () {
    final envFile = newEnvFile()..writeAsStringSync('A=1\nREVIEW_DEMO_CODE=\n');

    final changed = writeReviewDemoCode(envFile, 'new');

    expect(changed, isTrue);
    expect(envFile.readAsStringSync(), 'A=1\nREVIEW_DEMO_CODE=new\n');
  });

  test('default leaves a non-blank line untouched', () {
    final envFile = newEnvFile()..writeAsStringSync('REVIEW_DEMO_CODE=keep\n');

    final changed = writeReviewDemoCode(envFile, 'new');

    expect(changed, isFalse);
    expect(envFile.readAsStringSync(), 'REVIEW_DEMO_CODE=keep\n');
  });

  test('appends when absent, creating the file if needed', () {
    final envFile = newEnvFile();
    final changed = writeReviewDemoCode(envFile, 'new', overwrite: true);

    expect(changed, isTrue);
    expect(envFile.readAsStringSync(), 'REVIEW_DEMO_CODE=new\n');
  });
}
