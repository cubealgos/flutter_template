import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/dry_run_ledger.dart';
import 'package:appwrite_tool/src/git_inspector.dart';

/// Applies the schema, then deploys every Function and Site, to whatever
/// project [actions] is wired to — from a clean, tagged commit only, and a
/// real run only after a dry run of the same commit.
class Promoter {
  /// Creates a promoter.
  Promoter({
    required this.git,
    required this.actions,
    required this.ledger,
    required this.schema,
    required this.log,
  });

  /// The checkout inspector.
  final GitInspector git;

  /// The steps.
  final PromotionActions actions;

  /// The dry-run record.
  final DryRunLedger ledger;

  /// What to promote.
  final AppwriteSchema schema;

  /// Progress output.
  final void Function(String line) log;

  /// Runs the promotion; returns true when every step succeeded. Throws
  /// [PromotionRefusedException] before changing anything if a guard fails.
  Future<bool> run({required bool dryRun}) async {
    final sha = await _guard(dryRun: dryRun);
    log(
      '${dryRun ? 'DRY RUN of' : 'Promoting'} '
      '${await git.exactTag()} ($sha)',
    );
    final ok = await _steps(dryRun: dryRun);
    if (ok && dryRun) ledger.record(sha);
    log(
      ok
          ? (dryRun ? 'Dry run succeeded.' : 'Promotion finished.')
          : 'Stopped at the first failure; later steps did not run. Open a '
                'new issue for the failed deploy.',
    );

    return ok;
  }

  Future<String> _guard({required bool dryRun}) async {
    final tag = await git.exactTag();
    if (tag == null) {
      throw const PromotionRefusedException(
        'HEAD is not exactly at a tag. Check out the release tag first '
        '(git checkout <pkg>-vX.Y.Z).',
      );
    }
    if (!await git.isClean()) {
      throw const PromotionRefusedException(
        'the working tree has uncommitted changes.',
      );
    }
    final sha = await git.headSha();
    if (!dryRun && !ledger.has(sha)) {
      throw const PromotionRefusedException(
        'no successful dry run recorded for this commit. Run with --dry-run '
        'first.',
      );
    }

    return sha;
  }

  Future<bool> _steps({required bool dryRun}) async {
    var ok = true;
    log('Schema:');
    final changes = await actions.provision(dryRun: dryRun);
    log(
      changes.isEmpty
          ? '  up to date'
          : changes.map((c) => '  - $c').join('\n'),
    );

    for (final function in schema.functions) {
      log('Function ${function.id}');
      if (!await actions.deployFunction(function, dryRun: dryRun)) {
        ok = false;
        break;
      }
    }
    if (ok) {
      for (final site in schema.sites) {
        log('Site ${site.id}');
        if (!await actions.deploySite(site, dryRun: dryRun)) {
          ok = false;
          break;
        }
      }
    }

    return ok;
  }
}

/// The mutating (or, in a dry run, reporting) steps of a promotion, behind
/// an interface so `Promoter`'s ordering and guards are unit-tested.
abstract class PromotionActions {
  /// Applies the schema; returns the changes (or, in a [dryRun], the ones
  /// that would be made).
  Future<List<String>> provision({required bool dryRun});

  /// Deploys one Function; false on a failed build.
  Future<bool> deployFunction(FunctionSchema function, {required bool dryRun});

  /// Deploys one Site; false on failure.
  Future<bool> deploySite(SiteSchema site, {required bool dryRun});
}

/// A promotion that must not proceed.
class PromotionRefusedException implements Exception {
  /// Creates the exception with the human-readable [reason].
  const PromotionRefusedException(this.reason);

  /// Why.
  final String reason;

  @override
  String toString() => 'Refusing to promote: $reason';
}
