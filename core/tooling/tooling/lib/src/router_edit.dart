import 'package:tooling/src/feature_templates.dart';

/// The result of trying to wire a route into `router.dart`'s source text.
typedef RouterEditResult = ({String? source, String? reason});

/// Inserts a feature's import, `TypedGoRoute` entry and route class into the
/// text of `apps/app/lib/app/router.dart`, or reports why it cannot.
///
/// Anchors: the `routes:` list of the `BootstrapRoute` annotation (its
/// closing `],` followed by `)` and `class BootstrapRoute`) and the existing
/// `import 'package:<app>/...'` block. If either is missing the edit is
/// refused as a whole — nothing is half-applied.
class RouterEdit {
  /// Creates an edit that wires in the feature [templates] describe.
  const RouterEdit(this.templates);

  /// The generated texts to insert (and the app package they import from).
  final FeatureTemplates templates;

  static final RegExp _listEnd = RegExp(r'\n  \],\n\)\nclass BootstrapRoute\b');

  /// Returns the new source (`source`), or `null` plus a `reason`.
  // Splices the templates' texts into the router: that is its whole job.
  // ignore: solid_lints/feature_envy
  RouterEditResult apply(String source) {
    final routeClass = templates.names.routeClass;
    if (RegExp('class $routeClass\\b').hasMatch(source)) {
      return (source: null, reason: 'router.dart already declares $routeClass');
    }
    final listEnd = _listEnd.firstMatch(source);
    if (listEnd == null) {
      return (
        source: null,
        reason: "could not find BootstrapRoute's `routes:` list",
      );
    }
    final withEntry =
        '${source.substring(0, listEnd.start)}\n${templates.routeEntry()}'
        '${source.substring(listEnd.start)}';
    final withImport = _insertImport(withEntry, templates.routerImport());
    if (withImport == null) {
      return (source: null, reason: 'could not find the app import block');
    }

    return (
      source: '${withImport.trimRight()}\n\n${templates.routeClassSource()}',
      reason: null,
    );
  }

  String? _insertImport(String source, String importLine) {
    final prefix = "import 'package:${templates.appPackage}/";
    final lines = source.split('\n');
    final appImports = <int>[
      for (var i = 0; i < lines.length; i++)
        if (lines[i].startsWith(prefix)) i,
    ];
    if (appImports.isEmpty) return null;
    final at = appImports.firstWhere(
      (i) => lines[i].compareTo(importLine) > 0,
      orElse: () => appImports.last + 1,
    );
    lines.insert(at, importLine);

    return lines.join('\n');
  }
}
