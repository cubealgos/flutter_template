import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/workspace_purl_namespace.dart';

import 'support/temp_workspace.dart';

void main() {
  // Assigned in setUp/read throughout the tests, cleaned up in tearDown —
  // the standard package:test fixture-per-test pattern.
  // ignore: solid_lints/avoid_late_keyword
  late TempWorkspace workspace;

  setUp(() => workspace = TempWorkspace.create('workspace_purl_namespace_'));
  tearDown(() => workspace.dispose());

  test('strips a trailing _workspace suffix', () {
    workspace.writeFile('pubspec.yaml', 'name: example_app_workspace\n');

    expect(workspacePurlNamespace(workspace.root.path), 'example_app');
  });

  test(
    "a renamed clone's own workspace name is read back, not a fixed one",
    () {
      workspace.writeFile('pubspec.yaml', 'name: acme_notes_workspace\n');

      expect(workspacePurlNamespace(workspace.root.path), 'acme_notes');
    },
  );

  test('a name with no _workspace suffix is used verbatim', () {
    workspace.writeFile('pubspec.yaml', 'name: acme_notes\n');

    expect(workspacePurlNamespace(workspace.root.path), 'acme_notes');
  });

  test('fails loudly when the root pubspec.yaml is missing', () {
    expect(
      () => workspacePurlNamespace(workspace.root.path),
      throwsA(isA<CommandFailure>()),
    );
  });

  test('fails loudly when the root pubspec.yaml has no name:', () {
    workspace.writeFile('pubspec.yaml', 'publish_to: none\n');

    expect(
      () => workspacePurlNamespace(workspace.root.path),
      throwsA(isA<CommandFailure>()),
    );
  });
}
