import 'package:test/test.dart';
import 'package:tooling/src/branch_families.dart';

/// A completeness guard: the six families this repo's workflow tooling
/// recognizes, spelled out independently of [branchFamilies] so a future
/// addition or removal there fails this test loudly instead of silently
/// changing behavior.
const List<String> _expectedFamilies = <String>[
  'feature',
  'bugfix',
  'chore',
  'documentation',
  'release',
  'hotfix',
];

void main() {
  test('branchFamilies is exactly the six documented families', () {
    expect(branchFamilies, _expectedFamilies);
  });

  test('baseBranchFor: hotfix branches from production', () {
    expect(baseBranchFor('hotfix'), 'production');
  });

  test('baseBranchFor: every other family branches from development', () {
    for (final family in _expectedFamilies.where((f) => f != 'hotfix')) {
      expect(baseBranchFor(family), 'development', reason: family);
    }
  });

  test('slugPattern accepts lowercase kebab-case', () {
    expect(slugPattern.hasMatch('add-widget'), isTrue);
    expect(slugPattern.hasMatch('a'), isTrue);
    expect(slugPattern.hasMatch('a1-b2'), isTrue);
  });

  test('slugPattern rejects uppercase, underscores and stray hyphens', () {
    expect(slugPattern.hasMatch('Add-Widget'), isFalse);
    expect(slugPattern.hasMatch('add_widget'), isFalse);
    expect(slugPattern.hasMatch('-add-widget'), isFalse);
    expect(slugPattern.hasMatch('add-widget-'), isFalse);
    expect(slugPattern.hasMatch(''), isFalse);
  });

  test('branchNamePattern accepts every family with a valid slug', () {
    for (final family in _expectedFamilies) {
      expect(
        branchNamePattern.hasMatch('$family/11-workflow-tooling'),
        isTrue,
        reason: family,
      );
    }
  });

  test(
    'branchNamePattern rejects unknown/retired families and missing parts',
    () {
      for (final branch in <String>[
        'feat/11-workflow-tooling',
        'fix/11-workflow-tooling',
        'docs/11-workflow-tooling',
        'feature/workflow-tooling',
        'feature/11',
        'feature/11-',
      ]) {
        expect(branchNamePattern.hasMatch(branch), isFalse, reason: branch);
      }
    },
  );

  test('releasePackageVersionPattern accepts <pkg>-v<semver>', () {
    expect(
      releasePackageVersionPattern.hasMatch('release/tooling-v1.2.3'),
      isTrue,
    );
    expect(
      releasePackageVersionPattern.hasMatch('release/flutter-template-v0.1.0'),
      isTrue,
    );
  });

  test('releasePackageVersionPattern rejects a non-semver suffix', () {
    expect(
      releasePackageVersionPattern.hasMatch('release/tooling-v1.2'),
      isFalse,
    );
    expect(
      releasePackageVersionPattern.hasMatch('release/tooling-1.2.3'),
      isFalse,
    );
  });

  test('typeLabelFor maps each labeled family to its type/* label', () {
    expect(typeLabelFor('feature'), 'type/feature');
    expect(typeLabelFor('bugfix'), 'type/bugfix');
    expect(typeLabelFor('chore'), 'type/chore');
    expect(typeLabelFor('documentation'), 'type/docs');
  });

  test(
    'typeLabelFor returns null for release/hotfix (no such label exists)',
    () {
      expect(typeLabelFor('release'), isNull);
      expect(typeLabelFor('hotfix'), isNull);
    },
  );
}
