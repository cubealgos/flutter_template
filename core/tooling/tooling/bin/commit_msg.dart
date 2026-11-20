import 'dart:io';

import 'package:tooling/src/commit_rule.dart';

/// A `commit-msg` git hook: validates the subject line of the commit message
/// file at `args[0]` against [validateCommitSubject].
///
/// Usage: `dart run tooling:commit_msg <path-to-commit-msg-file>`
void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Usage: commit_msg <path-to-commit-msg-file>');
    exit(1);
  }

  final file = File(args.first);
  if (!file.existsSync()) {
    stderr.writeln('Commit message file not found: ${args.first}');
    exit(1);
  }

  final lines = file.readAsLinesSync();
  final subject = lines.isEmpty ? '' : lines.first;

  final error = validateCommitSubject(subject);
  if (error != null) {
    stderr
      ..writeln('commit-msg hook rejected this commit:')
      ..writeln()
      ..writeln('  $error')
      ..writeln();
    exit(1);
  }

  exit(0);
}
