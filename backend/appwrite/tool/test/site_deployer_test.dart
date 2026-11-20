import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/deploy/site_deployer.dart';
import 'package:appwrite_tool/src/deploy/sites_gateway.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'fakes/fake_sites_gateway.dart';
import 'support/temp_dir.dart';

const _site = SiteSchema(
  id: 'app',
  name: 'App',
  buildOutputPath: 'build/web',
  buildCommand: 'make web',
);

Future<void> _noWait(Duration _) => Future<void>.value();

void _writeBuild(Directory repo) {
  Directory(p.join(repo.path, 'build', 'web')).createSync(recursive: true);
  File(p.join(repo.path, 'build', 'web', 'index.html'))
      .writeAsStringSync('<html></html>');
}

void main() {
  test('creates an absent site, uploads, and reports ready', () async {
    final repo = tempDir('site_repo');
    final scratch = tempDir('site_scratch');
    _writeBuild(repo);
    final gateway = FakeSitesGateway();

    final result = await SiteDeployer(
      gateway,
      wait: _noWait,
    ).deploy(_site, repo, scratch: scratch);

    expect(result.succeeded, isTrue);
    expect(result.deploymentId, 'dep-1');
    expect(gateway.calls, <String>['createSite(app)', 'upload(app)']);
    expect(gateway.uploadedBytes, greaterThan(0));
    expect(scratch.listSync(), isEmpty, reason: 'archive cleaned up');
  });

  test('does not recreate an existing site', () async {
    final repo = tempDir('site_repo');
    final scratch = tempDir('site_scratch');
    _writeBuild(repo);
    final gateway = FakeSitesGateway(existing: <String>{'app'});

    await SiteDeployer(
      gateway,
      wait: _noWait,
    ).deploy(_site, repo, scratch: scratch);

    expect(gateway.calls, <String>['upload(app)']);
  });

  test('polls until the build finishes', () async {
    final repo = tempDir('site_repo');
    final scratch = tempDir('site_scratch');
    _writeBuild(repo);
    final gateway = FakeSitesGateway(
      builds: const <SiteBuild>[
        SiteBuild(status: 'building', logs: '', isFinished: false),
        SiteBuild(status: 'ready', logs: '', isFinished: true),
      ],
    );

    final result = await SiteDeployer(
      gateway,
      wait: _noWait,
    ).deploy(_site, repo, scratch: scratch);

    expect(result.succeeded, isTrue);
  });

  test('reports a failed build with its log', () async {
    final repo = tempDir('site_repo');
    final scratch = tempDir('site_scratch');
    _writeBuild(repo);
    final gateway = FakeSitesGateway(
      builds: const <SiteBuild>[
        SiteBuild(status: 'failed', logs: 'boom', isFinished: true),
      ],
    );

    final result = await SiteDeployer(
      gateway,
      wait: _noWait,
    ).deploy(_site, repo, scratch: scratch);

    expect(result.succeeded, isFalse);
    expect(result.summary, contains('boom'));
  });

  test('gives up when the build never finishes', () async {
    final repo = tempDir('site_repo');
    final scratch = tempDir('site_scratch');
    _writeBuild(repo);
    final gateway = FakeSitesGateway(
      builds: const <SiteBuild>[
        SiteBuild(status: 'building', logs: '', isFinished: false),
      ],
    );

    final result = await SiteDeployer(
      gateway,
      wait: _noWait,
      timeout: Duration.zero,
    ).deploy(_site, repo, scratch: scratch);

    expect(result.succeeded, isFalse);
    expect(result.summary, contains('timed out'));
  });

  test('a missing build names the build command and changes nothing', () async {
    final repo = tempDir('site_repo');
    final scratch = tempDir('site_scratch');
    final gateway = FakeSitesGateway();

    await expectLater(
      SiteDeployer(gateway).deploy(_site, repo, scratch: scratch),
      throwsA(
        isA<SiteBuildMissingException>().having(
          (e) => e.toString(),
          'message',
          contains('make web'),
        ),
      ),
    );
    expect(gateway.calls, isEmpty);
  });

  test('a dry run changes nothing', () async {
    final repo = tempDir('site_repo');
    _writeBuild(repo);
    final gateway = FakeSitesGateway();

    final result = await SiteDeployer(gateway).dryRun(_site, repo);

    expect(result.summary, contains('would create and deploy'));
    expect(gateway.calls, isEmpty);
  });
}
