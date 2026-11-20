// Idempotently seeds the App Review demo access the store review needs: a real
// Appwrite user with no password (email/password auth is disabled
// project-wide by `Provisioner` anyway — see its `unusedAuthMethods`
// dartdoc for the account-takeover finding that requires it), plus the
// `api` Function's (`review_demo_sign_in` action) `REVIEW_DEMO_USER_ID`/`REVIEW_DEMO_CODE`
// variables pointing at that account. The app's sign-in screen only ever
// calls `AuthService.signInWithReviewCode` with a code the reviewer types
// by hand — see `apps/app/README.md`'s "App Review demo access" section
// for the full design.
//
// Usage: `dart run bin/seed_review_demo_account.dart [--rotate] <email>` (the email
// isn't a secret, so it may be passed as an argument). The review code
// never is: a fresh run generates one (`generateReviewDemoCode`) and
// writes it to the shared, gitignored `backend/appwrite/tool/.env.local` next
// to `APPWRITE_API_KEY` etc., under `REVIEW_DEMO_CODE`, and this script
// never prints the value itself. Rerunning against an already-seeded
// account is a pure no-op. `--rotate` instead always generates a fresh code,
// replaces the old one in the function and `.env.local`, and warns that the
// store review notes must be updated.
import 'dart:io';

import 'package:appwrite_tool/src/appwrite_client.dart';
import 'package:appwrite_tool/src/backend_env.dart';
import 'package:appwrite_tool/src/dart_appwrite_review_demo_account_gateway.dart';
import 'package:appwrite_tool/src/repo_root.dart';
import 'package:appwrite_tool/src/review_demo_account.dart';
import 'package:appwrite_tool/src/review_demo_code_env_file.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final rotate = args.contains('--rotate');
  final positional = args.where((a) => a != '--rotate').toList();
  if (positional.length != 1 || positional.single.startsWith('-')) {
    stderr.writeln(
      'Usage: dart run bin/seed_review_demo_account.dart [--rotate] <email>',
    );
    exitCode = 1;

    return;
  }
  final email = positional.single;

  final BackendEnv env;
  try {
    env = BackendEnv.load();
  } on MissingBackendConfigException catch (e) {
    stderr.writeln(e);
    exitCode = 1;

    return;
  }

  final client = buildClient(env);
  final gateway = DartAppwriteReviewDemoAccountGateway(client);
  final result = await seedReviewDemoAccount(
    gateway: gateway,
    email: email,
    rotate: rotate,
  );

  final generatedCode = result.generatedCode;
  if (generatedCode == null) {
    stdout.writeln(
      'The api review_demo_sign_in action is already configured for $email '
      '(${result.userId}) - nothing to do.',
    );

    return;
  }

  final envLocalFile = _writeReviewDemoCode(generatedCode, rotate: rotate);
  if (rotate) {
    stdout.writeln(
      'WARNING: the previous review code no longer works. Update the review '
      'notes in App Store Connect / Play Console with the new one.',
    );
  }
  stdout.writeln(
    'Configured the api review_demo_sign_in action for $email '
    '(${result.userId}).\n'
    'Wrote its review code to ${envLocalFile.path} (REVIEW_DEMO_CODE) - '
    'not printed here. Copy it from that file into the App Store Connect / '
    'Play Console review notes.',
  );
}

/// Writes the code into the *shared* `.env.local` every worktree of this
/// clone resolves to (`findSharedBackendDir` - see `repo_root.dart`), the
/// same file that holds `APPWRITE_API_KEY` etc. See [writeReviewDemoCode]
/// for when an existing line is replaced.
File _writeReviewDemoCode(String code, {required bool rotate}) {
  final sharedDir = findSharedBackendDir(Directory.current);
  if (sharedDir == null) {
    throw StateError(
      'Could not resolve the shared secrets directory (git rev-parse '
      '--git-common-dir failed) - is ${Directory.current.path} inside a '
      'git repository?',
    );
  }

  final file = File(p.join(sharedDir.path, 'appwrite', 'tool', '.env.local'));
  writeReviewDemoCode(file, code, overwrite: rotate);

  return file;
}
