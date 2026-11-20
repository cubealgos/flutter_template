import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:mvc_lints/src/view_detection.dart';

/// Forbids a `*_view.dart` file from declaring widgets beyond its view class.
///
/// A view file holds exactly one widget: the view itself. Every helper
/// widget, private or public, lives in the feature's `widgets/` folder, one
/// public widget per file, where `AvoidViewRestrictedImportsRule` and
/// `AvoidViewNavigationCallsRule` still apply to it (see
/// [isViewCompilationUnit]). Any other class extending `StatelessWidget`,
/// `StatefulWidget`, `InheritedWidget` or the `ViewWidget` family
/// ([extraWidgetClasses]) is flagged.
class AvoidExtraWidgetsInViewFilesRule extends AnalysisRule {
  /// Creates a new instance of [AvoidExtraWidgetsInViewFilesRule].
  AvoidExtraWidgetsInViewFilesRule()
    : super(
        name: lintName,
        description:
            'A *_view.dart file may declare only its view widget; helper '
            'widgets belong in the feature widgets/ folder.',
      );

  /// The rule name, as referenced from `analysis_options.yaml`.
  static const String lintName = 'avoid_extra_widgets_in_view_files';

  static const LintCode _code = LintCode(
    lintName,
    "A view file may declare only its view widget — move '{0}' into a "
    'widgets/ folder, one public widget per file.',
    correctionMessage:
        'Move this class to widgets/<snake_case_name>.dart next to the view, '
        'make it public and documented, and pass it data and callbacks '
        'instead of the controller.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => _code;

  // Only inspects `extends` clauses by name — available from the parsed
  // (unresolved) AST, so it never needs a resolved unit.
  @override
  bool get canUseParsedResult => true;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final definingUnit = context.definingUnit;
    if (!definingUnit.file.path.endsWith('_view.dart')) return;

    registry.addCompilationUnit(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidExtraWidgetsInViewFilesRule rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    for (final widget in extraWidgetClasses(node)) {
      rule.reportAtToken(
        widget.namePart.typeName,
        arguments: [widget.namePart.typeName.lexeme],
      );
    }
  }
}
