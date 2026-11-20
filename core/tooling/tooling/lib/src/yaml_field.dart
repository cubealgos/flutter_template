import 'package:tooling/src/command_failure.dart';
import 'package:yaml/yaml.dart';

/// Where a [requireYamlField] error message points: the file `path`, the
/// kind of entry being parsed (`entryNoun`, e.g. `"an entry"`, `"a
/// verified entry"`) and, once known, the entry's own `package` value as
/// `context` — reused across every field of the same entry so the caller
/// builds it once.
typedef YamlEntryContext = ({String path, String entryNoun, String? context});

/// Returns `raw[field]` as a non-empty [String], or throws [CommandFailure]
/// describing where via [ctx]. Shared by `licence_exception.dart` and
/// `verified_licence.dart` so both `tool/licence-exceptions.yaml` list
/// parsers (`exceptions:` and `verified:`) report the same shape of
/// error.
String requireYamlField(YamlMap raw, String field, YamlEntryContext ctx) {
  final value = raw[field];
  if (value is String && value.isNotEmpty) return value;
  final suffix = ctx.context == null ? '' : " for '${ctx.context}'";
  throw CommandFailure(
    "${ctx.path}: ${ctx.entryNoun}$suffix is missing '$field'.",
  );
}
