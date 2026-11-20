import 'dart:io';

const String _prefix = 'REVIEW_DEMO_CODE=';

/// Writes `REVIEW_DEMO_CODE=[code]` into the env [file] (the shared
/// `.env.local`), creating it if needed.
///
/// An existing `REVIEW_DEMO_CODE=` line is replaced **in place** (never
/// duplicated) when its value is blank, or when [overwrite] is true
/// (`--rotate`); a non-blank line is otherwise left alone. With no such
/// line the entry is appended. Returns true if the file was changed.
bool writeReviewDemoCode(File file, String code, {bool overwrite = false}) {
  final lines = file.existsSync() ? file.readAsLinesSync() : <String>[];
  final index = lines.indexWhere((line) => line.trim().startsWith(_prefix));

  if (index == -1) {
    file.parent.createSync(recursive: true);
    lines.add('$_prefix$code');
  } else {
    final value = lines[index].trim().substring(_prefix.length).trim();
    if (value.isNotEmpty && !overwrite) return false;
    lines[index] = '$_prefix$code';
  }
  file.writeAsStringSync('${lines.join('\n')}\n');

  return true;
}
