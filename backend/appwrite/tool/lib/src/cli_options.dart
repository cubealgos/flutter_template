import 'package:appwrite_tool/src/backend_env.dart';
import 'package:appwrite_tool/src/backend_target.dart';

/// The flags every deploy-side command shares, split from its positional
/// arguments.
class CliOptions {
  /// Creates options.
  const CliOptions({
    required this.target,
    required this.dryRun,
    required this.positional,
  });

  /// Parses [args]: `--production` selects [BackendTarget.production],
  /// `--dry-run` sets [dryRun]; everything else is [positional].
  factory CliOptions.parse(List<String> args) => CliOptions(
    target: args.contains(productionFlag)
        ? BackendTarget.production
        : BackendTarget.dev,
    dryRun: args.contains('--dry-run'),
    positional: args.where((a) => !a.startsWith('--')).toList(),
  );

  /// The project the command runs against.
  final BackendTarget target;

  /// Whether the command only reports what it would do.
  final bool dryRun;

  /// Arguments that are not flags.
  final List<String> positional;

  /// Loads the [BackendEnv] for [target]; production only because
  /// `--production` was passed (that is what [target] encodes).
  BackendEnv loadEnv({required String keyId}) => BackendEnv.load(
    target: target,
    allowProduction: target == BackendTarget.production,
    keyId: keyId,
  );
}
