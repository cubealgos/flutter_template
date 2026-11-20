import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:mvc_lints/src/view_detection.dart';

/// Forbids an MVC view from importing navigation, URL-launching, backend or
/// data-layer packages directly.
///
/// A view (a file named `*_view.dart`, or a class extending `ViewWidget` or
/// `InheritedViewWidget` — see [isViewCompilationUnit]) stays dumb: it reads
/// state and renders it, and reaches everything else — navigation, external
/// URLs, the backend, persistence — through a controller or service that is
/// injected into it, not through a direct import. This rule flags an import
/// of `package:go_router`, `package:url_launcher`, `package:appwrite`, or
/// anything under a `repositories/` or `data/` path in a view file.
///
/// Rationale: views stay dumb and reach the data layer only through an
/// injected controller. See `AvoidViewNavigationCallsRule` for the companion rule
/// covering direct navigation calls.
class AvoidViewRestrictedImportsRule extends AnalysisRule {
  /// Creates a new instance of [AvoidViewRestrictedImportsRule].
  AvoidViewRestrictedImportsRule()
    : super(
        name: lintName,
        description:
            'Views may not import package:go_router, package:url_launcher, '
            'package:appwrite, or anything under repositories/ or data/.',
      );

  /// The rule name, as referenced from `analysis_options.yaml`.
  static const String lintName = 'avoid_view_restricted_imports';

  static const LintCode _code = LintCode(
    lintName,
    "Views may not import '{0}' — inject a controller/service that wraps "
    'it instead. See the mvc-dumb-views-service-mediated-navigation note.',
    correctionMessage:
        'Move this import behind a controller or service and inject that '
        'instead of importing it directly from the view.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => _code;

  // This rule only inspects import URIs and `extends` clauses — both
  // available from the parsed (unresolved) AST — so it never needs a
  // resolved unit.
  @override
  bool get canUseParsedResult => true;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final definingUnit = context.definingUnit;
    final isView = isViewCompilationUnit(
      path: definingUnit.file.path,
      unit: definingUnit.unit,
    );
    if (!isView) return;

    registry.addImportDirective(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidViewRestrictedImportsRule rule;

  @override
  void visitImportDirective(ImportDirective node) {
    final uriString = node.uri.stringValue;
    if (uriString == null) return;
    if (!isBannedViewImport(uriString)) return;

    rule.reportAtNode(node, arguments: [uriString]);
  }
}
