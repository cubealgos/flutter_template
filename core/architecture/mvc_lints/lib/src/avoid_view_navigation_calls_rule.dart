import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:mvc_lints/src/view_detection.dart';

/// Forbids an MVC view from navigating directly.
///
/// Companion to `AvoidViewRestrictedImportsRule`: even if `package:go_router`
/// were imported elsewhere and its extension methods pulled in transitively,
/// a view still may not call `Navigator.*` (any static or instance method on
/// the `Navigator` class) or `context.go`/`push`/`pop`/`replace`
/// ([bannedContextNavigationMethods]) — navigation is a controller's job,
/// mediated through an injected navigation service.
///
/// This is a syntactic check (matching on the identifier names `Navigator`
/// and `context`, not on resolved types), matching how [isViewCompilationUnit]
/// itself is syntactic — consistent with keeping this rule fast and
/// resolution-free.
class AvoidViewNavigationCallsRule extends AnalysisRule {
  /// Creates a new instance of [AvoidViewNavigationCallsRule].
  AvoidViewNavigationCallsRule()
    : super(
        name: lintName,
        description:
            'Views may not call Navigator.* or context.go/push/pop/replace.',
      );

  /// The rule name, as referenced from `analysis_options.yaml`.
  static const String lintName = 'avoid_view_navigation_calls';

  static const LintCode _code = LintCode(
    lintName,
    'Views may not call {0} — navigate through an injected controller/service '
    'instead. See the mvc-dumb-views-service-mediated-navigation note.',
    correctionMessage:
        'Move this navigation call into a controller and expose it to the '
        'view as a callback, or navigate via an injected navigation service.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => _code;

  // Matches on unresolved identifier names only (see the class doc) — never
  // needs a resolved unit.
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

    registry.addMethodInvocation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidViewNavigationCallsRule rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final description = bannedNavigationCallDescription(node);
    if (description == null) return;
    rule.reportAtNode(node, arguments: [description]);
  }
}
