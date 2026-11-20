import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/cli_failure.dart';
import 'package:appwrite_tool/src/deploy/site_deployer.dart';
import 'package:appwrite_tool/src/promoter.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:test/test.dart';

import 'fakes/fake_sites_gateway.dart';
import 'support/temp_dir.dart';

const _unauthorized = 401;
const _serverError = 500;

final _scopeError = AppwriteException(
  'app.123@service.localhost (role: applications) missing scopes '
      '(["sites.read"])',
  _unauthorized,
  'general_unauthorized_scope',
);

Future<(int, List<String>)> _run(Future<int> Function() body) async {
  final lines = <String>[];
  final code = await runReportingFailures(
    target: 'https://e/v1 (project dev)',
    operation: 'site dry run',
    err: lines.add,
    body: body,
  );

  return (code, lines);
}

void main() {
  test('a 401 missing scope from the gateway gives one clear line', () async {
    final repo = tempDir('cli_failure_repo');
    Directory('${repo.path}/build/web').createSync(recursive: true);
    File('${repo.path}/build/web/index.html').writeAsStringSync('x');
    const site = SiteSchema(
      id: 'app',
      name: 'App',
      buildOutputPath: 'build/web',
      buildCommand: 'make',
    );
    final deployer = SiteDeployer(FakeSitesGateway(existsError: _scopeError));

    final (code, lines) = await _run(() async {
      await deployer.dryRun(site, repo);

      return 0;
    });

    expect(code, isNonZero);
    expect(lines, hasLength(1));
    expect(
      lines.single,
      allOf(
        contains('site dry run failed on https://e/v1 (project dev)'),
        contains('["sites.read"]'),
        contains('dart run bin/api_keys.dart'),
        isNot(contains('#0')),
        isNot(contains('\n')),
      ),
    );
  });

  test('other Appwrite errors keep their message, without the key hint', () {
    final line = describeAppwriteFailure(
      target: 't',
      operation: 'op',
      error: AppwriteException('boom', _serverError, 'general_server_error'),
    );

    expect(line, 'op failed on t: boom');
  });

  test("this tool's own refusals also exit non-zero with one line", () async {
    final (code, lines) = await _run(
      () async => throw const PromotionRefusedException('not at a tag'),
    );

    expect(code, 1);
    expect(lines.single, contains('not at a tag'));
  });

  test('success passes the exit code through and prints nothing', () async {
    final (code, lines) = await _run(() async => 0);

    expect(code, 0);
    expect(lines, isEmpty);
  });
}
