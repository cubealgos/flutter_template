import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart' show parseString;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// File name suffixes that mark a Dart file as generated. Generated files
/// are never parsed for the map — they are implementation detail, not a
/// package's public API.
const List<String> generatedFileSuffixes = <String>[
  '.g.dart',
  '.freezed.dart',
  '.config.dart',
  '.mocks.dart',
  '.gr.dart',
];

/// Returns true if [fileName] ends with one of [generatedFileSuffixes].
bool isGeneratedFile(String fileName) =>
    generatedFileSuffixes.any(fileName.endsWith);

/// Walks up from [start] to find the repo root: the nearest ancestor
/// directory containing a `pubspec.yaml` with a top-level `workspace:` key.
Directory? findRepoRoot(Directory start) {
  var dir = start.absolute;
  while (true) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final doc = loadYaml(pubspec.readAsStringSync());
      if (doc is YamlMap && doc.containsKey('workspace')) {
        return dir;
      }
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}

/// Generates `docs/map.md` and `docs/map/<member>.md` for the workspace
/// rooted at [repoRoot], and can check a previously generated [GeneratedMap]
/// against what is currently on disk.
class MapGenerator {
  /// Creates a generator for the workspace rooted at [repoRoot].
  MapGenerator({required this.repoRoot});

  /// The workspace's root directory — where its `pubspec.yaml` (with the
  /// `workspace:` key) lives.
  final Directory repoRoot;

  /// Loads workspace members from the root pubspec's `workspace:` list,
  /// sorted by package name for deterministic output.
  List<WorkspaceMember> loadMembers() {
    final rootPubspecFile = File(p.join(repoRoot.path, 'pubspec.yaml'));
    final rootDoc = loadYaml(rootPubspecFile.readAsStringSync()) as YamlMap;
    final workspaceList = rootDoc['workspace'] as YamlList?;
    if (workspaceList == null) return const <WorkspaceMember>[];

    final members = <WorkspaceMember>[];
    for (final entry in workspaceList) {
      final relativePath = (entry as String).trim();
      final memberDir = Directory(p.join(repoRoot.path, relativePath));
      final memberPubspec = File(p.join(memberDir.path, 'pubspec.yaml'));
      if (!memberPubspec.existsSync()) {
        throw StateError(
          'Workspace member "$relativePath" has no pubspec.yaml at '
          '${memberPubspec.path}.',
        );
      }
      final doc = loadYaml(memberPubspec.readAsStringSync()) as YamlMap;
      final name =
          doc['name'] as String? ??
          (throw StateError(
            'Workspace member at $relativePath has no '
            'pubspec "name:".',
          ));
      final description = (doc['description'] as String?)?.trim() ?? '';
      members.add(
        WorkspaceMember(
          name: name,
          description: description,
          relativePath: relativePath.replaceAll(r'\', '/'),
          directory: memberDir,
        ),
      );
    }
    members.sort((a, b) => a.name.compareTo(b.name));

    return members;
  }

  /// Generates the full set of map files for the workspace.
  GeneratedMap generate() {
    final members = loadMembers();
    final files = <String, String>{};
    files['docs/map.md'] = _renderIndex(members);
    for (final member in members) {
      files['docs/map/${member.name}.md'] = _renderMember(member);
    }

    return GeneratedMap(files);
  }

  /// Compares [generated] against what is on disk under [repoRoot] and
  /// returns a list of human-readable drift descriptions (empty if there is
  /// no drift): missing files, extra files under `docs/map/`, and files
  /// whose content differs.
  List<String> checkAgainstDisk(GeneratedMap generated) {
    final drift = <String>[];

    for (final entry in generated.files.entries) {
      final onDisk = File(p.join(repoRoot.path, entry.key));
      if (!onDisk.existsSync()) {
        drift.add('missing: ${entry.key}');
        continue;
      }
      final current = onDisk.readAsStringSync();
      if (current != entry.value) {
        drift.add('stale: ${entry.key}');
      }
    }

    final mapDir = Directory(p.join(repoRoot.path, 'docs', 'map'));
    if (mapDir.existsSync()) {
      final expected = generated.files.keys
          .where((k) => k.startsWith('docs/map/'))
          .toSet();
      final onDiskFiles = mapDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .map((f) => 'docs/map/${p.basename(f.path)}');
      for (final path in onDiskFiles) {
        if (!expected.contains(path)) drift.add('extra: $path');
      }
    }

    drift.sort();

    return drift;
  }

  /// Writes [generated] to disk under [repoRoot], creating directories as
  /// needed, and removes any stray `docs/map/*.md` files that are no longer
  /// expected.
  void writeToDisk(GeneratedMap generated) {
    for (final entry in generated.files.entries) {
      final file = File(p.join(repoRoot.path, entry.key));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
    }

    final mapDir = Directory(p.join(repoRoot.path, 'docs', 'map'));
    if (mapDir.existsSync()) {
      final expected = generated.files.keys
          .where((k) => k.startsWith('docs/map/'))
          .toSet();
      for (final file in mapDir.listSync().whereType<File>()) {
        final relative = 'docs/map/${p.basename(file.path)}';
        if (file.path.endsWith('.md') && !expected.contains(relative)) {
          file.deleteSync();
        }
      }
    }
  }

  /// Returns the sorted list of non-generated `.dart` files under
  /// `<member>/lib`, as paths relative to the member directory (using `/`).
  List<String> _libFiles(WorkspaceMember member) {
    final libDir = Directory(p.join(member.directory.path, 'lib'));
    if (!libDir.existsSync()) return const <String>[];

    return libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !isGeneratedFile(p.basename(f.path)))
        .map(
          (f) => p
              .relative(f.path, from: member.directory.path)
              .replaceAll(r'\', '/'),
        )
        .toList()
      ..sort();
  }

  String _renderIndex(List<WorkspaceMember> members) {
    final buffer = StringBuffer()
      ..writeln('# Workspace map')
      ..writeln()
      ..writeln('Generated by `dart run tooling:map`. Do not hand-edit.')
      ..writeln()
      ..writeln('| package | description | path |')
      ..writeln('| --- | --- | --- |');
    for (final member in members) {
      final description = member.description.isEmpty
          ? '_(none)_'
          : member.description;
      buffer.writeln(
        '| [`${member.name}`](map/${member.name}.md) '
        '| $description | `${member.relativePath}` |',
      );
    }

    return buffer.toString();
  }

  String _renderMember(WorkspaceMember member) {
    final buffer = StringBuffer()
      ..writeln('# ${member.name}')
      ..writeln()
      ..writeln('Generated by `dart run tooling:map`. Do not hand-edit.')
      ..writeln()
      ..writeln('Path: `${member.relativePath}`');
    if (member.description.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(member.description);
    }

    final libFiles = _libFiles(member);
    for (final relativeFile in libFiles) {
      final file = File(p.join(member.directory.path, relativeFile));
      final declarations = _publicDeclarations(file);
      buffer
        ..writeln()
        ..writeln('## $relativeFile');
      if (declarations.isEmpty) {
        buffer
          ..writeln()
          ..writeln('_(no public top-level declarations)_');
      } else {
        buffer.writeln();
        for (final declaration in declarations) {
          buffer.writeln('- `$declaration`');
        }
      }
    }

    return buffer.toString();
  }

  /// Parses [file] with `package:analyzer` (source text only — the code is
  /// never imported/executed) and returns the signature of every public
  /// top-level class, enum, mixin, extension and function, in source order.
  List<String> _publicDeclarations(File file) {
    final content = file.readAsStringSync();
    final result = parseString(content: content, throwIfDiagnostics: false);
    final signatures = <String>[];
    for (final declaration in result.unit.declarations) {
      final signature = _describeDeclaration(declaration);
      if (signature != null) signatures.add(signature);
    }

    return signatures;
  }

  String? _describeDeclaration(CompilationUnitMember declaration) {
    return switch (declaration) {
      ClassDeclaration() => _describeClass(declaration),
      EnumDeclaration() => _describeEnum(declaration),
      MixinDeclaration() => _describeMixin(declaration),
      ExtensionDeclaration() => _describeExtension(declaration),
      FunctionDeclaration() => _describeFunction(declaration),
      _ => null,
    };
  }

  String? _describeClass(ClassDeclaration declaration) {
    final nameToken = declaration.namePart.typeName;
    if (nameToken.lexeme.startsWith('_')) return null;

    // A loop over (keyword, text) pairs rather than one `if` per modifier
    // keyword — same result, far fewer static branches to keep this under
    // the cyclomatic_complexity threshold.
    final modifierKeywords = <(Token?, String)>[
      (declaration.abstractKeyword, 'abstract'),
      (declaration.sealedKeyword, 'sealed'),
      (declaration.baseKeyword, 'base'),
      (declaration.interfaceKeyword, 'interface'),
      (declaration.finalKeyword, 'final'),
      (declaration.mixinKeyword, 'mixin'),
    ];
    final buffer = StringBuffer();
    for (final (keyword, text) in modifierKeywords) {
      if (keyword != null) buffer.write('$text ');
    }
    buffer.write('class ${nameToken.lexeme}');

    final typeParameters = declaration.namePart.typeParameters;
    if (typeParameters != null) buffer.write(typeParameters.toSource());

    // Likewise for the extends/with/implements clauses — every one of them
    // is just "if present, append its source", so a loop over the nullable
    // clauses (all of which are `AstNode`s with `toSource()`) replaces three
    // near-identical `if` statements with one.
    for (final clause in <AstNode?>[
      declaration.extendsClause,
      declaration.withClause,
      declaration.implementsClause,
    ]) {
      if (clause != null) buffer.write(' ${clause.toSource()}');
    }

    return buffer.toString();
  }

  String? _describeEnum(EnumDeclaration declaration) {
    final nameToken = declaration.namePart.typeName;
    if (nameToken.lexeme.startsWith('_')) return null;

    final values = declaration.body.constants
        .map((c) => c.name.lexeme)
        .join(', ');

    return 'enum ${nameToken.lexeme} { $values }';
  }

  String? _describeMixin(MixinDeclaration declaration) {
    if (declaration.name.lexeme.startsWith('_')) return null;

    final buffer = StringBuffer('mixin ${declaration.name.lexeme}');
    final typeParameters = declaration.typeParameters;
    if (typeParameters != null) buffer.write(typeParameters.toSource());
    final onClause = declaration.onClause;
    if (onClause != null) buffer.write(' ${onClause.toSource()}');
    final implementsClause = declaration.implementsClause;
    if (implementsClause != null) {
      buffer.write(' ${implementsClause.toSource()}');
    }

    return buffer.toString();
  }

  String? _describeExtension(ExtensionDeclaration declaration) {
    final name = declaration.name?.lexeme;
    if (name != null && name.startsWith('_')) return null;

    final buffer = StringBuffer('extension');
    if (name != null) buffer.write(' $name');
    final typeParameters = declaration.typeParameters;
    if (typeParameters != null) buffer.write(typeParameters.toSource());
    final onClause = declaration.onClause;
    if (onClause != null) {
      buffer.write(' on ${onClause.extendedType.toSource()}');
    }

    return buffer.toString();
  }

  String? _describeFunction(FunctionDeclaration declaration) {
    if (declaration.name.lexeme.startsWith('_')) return null;
    if (declaration.isGetter || declaration.isSetter) return null;

    final buffer = StringBuffer();
    final returnType = declaration.returnType?.toSource();
    if (returnType != null && returnType.isNotEmpty) {
      buffer.write('$returnType ');
    }
    buffer.write(declaration.name.lexeme);
    final typeParameters = declaration.functionExpression.typeParameters;
    if (typeParameters != null) buffer.write(typeParameters.toSource());
    final parameters = declaration.functionExpression.parameters;
    buffer.write(parameters?.toSource() ?? '()');

    return buffer.toString();
  }
}

/// A workspace member: a package listed under the root pubspec's
/// `workspace:` key.
class WorkspaceMember {
  /// Creates a member description for a package at [relativePath].
  WorkspaceMember({
    required this.name,
    required this.description,
    required this.relativePath,
    required this.directory,
  });

  /// The package's `name:` from its own pubspec.yaml.
  final String name;

  /// The package's `description:` from its own pubspec.yaml, or '' if unset.
  final String description;

  /// The member's path relative to the repo root, using `/` separators
  /// (e.g. `apps/app`).
  final String relativePath;

  /// The member's directory on disk.
  final Directory directory;
}

/// The generated files, keyed by their path relative to the repo root
/// (using `/` separators), e.g. `docs/map.md`, `docs/map/tooling.md`.
class GeneratedMap {
  /// Wraps an already-rendered set of [files].
  GeneratedMap(this.files);

  /// The generated file contents, keyed by their repo-relative path.
  final Map<String, String> files;
}
