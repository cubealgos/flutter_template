import 'package:analyzer/dart/ast/ast.dart';

/// Class names that mark a class as an MVC view per the
/// `mvc-dumb-views-service-mediated-navigation` convention: a view stays
/// dumb and never navigates, launches URLs, or touches data directly.
const Set<String> viewSuperclassNames = <String>{
  'ViewWidget',
  'InheritedViewWidget',
};

/// Directory names whose files are views by location: helper widgets live in
/// a feature's `widgets/` folder and page layouts in its `layouts/` folder,
/// and both stay as dumb as the view itself.
const Set<String> viewDirectoryNames = <String>{'widgets', 'layouts'};

/// Returns true if [unit] (the compilation unit at [path]) should be treated
/// as an MVC view for the purposes of the `avoid_view_restricted_imports` and
/// `avoid_view_navigation_calls` rules.
///
/// A unit counts as a view when its file name ends with `_view.dart`, when
/// its path has a directory segment in [viewDirectoryNames] (`widgets/` or
/// `layouts/`), or when it declares at least one class whose `extends`
/// clause names a class in [viewSuperclassNames] (typically `ViewWidget` or
/// `InheritedViewWidget`).
bool isViewCompilationUnit({
  required String path,
  required CompilationUnit unit,
}) {
  if (path.endsWith('_view.dart')) return true;

  final directories = path.replaceAll(r'\', '/').split('/')..removeLast();
  if (directories.any(viewDirectoryNames.contains)) return true;

  for (final declaration in unit.declarations) {
    if (declaration is! ClassDeclaration) continue;
    final superclassName = declaration.extendsClause?.superclass.name.lexeme;
    if (superclassName != null &&
        viewSuperclassNames.contains(superclassName)) {
      return true;
    }
  }

  return false;
}

/// Package names a view may never import directly, per the MVC boundary:
/// navigation ([goRouterPackage]), launching external URLs
/// ([urlLauncherPackage]), and the backend SDK ([appwritePackage]) all belong
/// behind an injected service, not in the view.
const String goRouterPackage = 'go_router';

/// See [goRouterPackage].
const String urlLauncherPackage = 'url_launcher';

/// See [goRouterPackage].
const String appwritePackage = 'appwrite';

const Set<String> _bannedImportPackages = <String>{
  goRouterPackage,
  urlLauncherPackage,
  appwritePackage,
};

/// Path segments that mark an import as reaching into the data layer, which
/// a view may not do directly — it goes through an injected controller.
const Set<String> _bannedImportPathSegments = <String>{'repositories', 'data'};

/// Returns true if the import URI [uriString] (e.g.
/// `package:go_router/go_router.dart` or `../data/user_repository.dart` —
/// the literal's resolved string value, with no surrounding quotes) is one a
/// view may not import: [goRouterPackage], [urlLauncherPackage],
/// [appwritePackage], or anything under a `repositories/` or `data/` path
/// segment.
bool isBannedViewImport(String uriString) {
  final segments = uriString.split('/');

  if (uriString.startsWith('package:')) {
    final packageName = segments.first.substring('package:'.length);
    if (_bannedImportPackages.contains(packageName)) return true;
  }

  return segments.any(_bannedImportPathSegments.contains);
}

/// Method names on a `BuildContext` (conventionally named `context`) that
/// navigate — the `go_router` extension methods a view must not call
/// directly.
const Set<String> bannedContextNavigationMethods = <String>{
  'go',
  'push',
  'pop',
  'replace',
};

/// Returns a human-readable description of [node] (e.g. `'Navigator.push'`)
/// if it is a navigation call a view may not make — a call on a target named
/// `Navigator` (any method: static constructors like `Navigator.of` included,
/// since that itself is a call on `Navigator`), or a call to
/// `context.<method>` where `<method>` is in
/// [bannedContextNavigationMethods] — or `null` if [node] is allowed.
///
/// This is a syntactic check, matching on the identifier names `Navigator`
/// and `context` rather than on resolved types, consistent with
/// [isViewCompilationUnit] and [isBannedViewImport] also being syntactic —
/// it keeps the rule fast and independent of type resolution.
String? bannedNavigationCallDescription(MethodInvocation node) {
  final target = node.target;
  if (target is! SimpleIdentifier) return null;

  final methodName = node.methodName.name;
  if (target.name == 'Navigator') return 'Navigator.$methodName';
  if (target.name == 'context' &&
      bannedContextNavigationMethods.contains(methodName)) {
    return 'context.$methodName';
  }
  return null;
}

/// Superclass names that make a class a widget for the purposes of
/// `avoid_extra_widgets_in_view_files`: the Flutter base widgets plus the
/// [viewSuperclassNames] family.
const Set<String> widgetSuperclassNames = <String>{
  'StatelessWidget',
  'StatefulWidget',
  'InheritedWidget',
  ...viewSuperclassNames,
};

/// Returns the widget classes in [unit] other than its view class.
///
/// A widget class is one whose `extends` clause names a class in
/// [widgetSuperclassNames]. The view class is the first widget class
/// extending [viewSuperclassNames] or, when there is none, the first widget
/// class in the file; every other widget class is returned, in declaration
/// order. `State` subclasses are not widgets and are never returned.
List<ClassDeclaration> extraWidgetClasses(CompilationUnit unit) {
  final widgets = <ClassDeclaration>[
    for (final declaration in unit.declarations)
      if (declaration is ClassDeclaration &&
          widgetSuperclassNames.contains(
            declaration.extendsClause?.superclass.name.lexeme,
          ))
        declaration,
  ];
  if (widgets.isEmpty) return const <ClassDeclaration>[];

  final view = widgets.firstWhere(
    (widget) => viewSuperclassNames.contains(
      widget.extendsClause?.superclass.name.lexeme,
    ),
    orElse: () => widgets.first,
  );
  return widgets.where((widget) => widget != view).toList();
}
