/// Parses the `## Acceptance criteria` section of a GitHub issue body.
library;

final RegExp _headingPattern = RegExp(r'^#{1,6}\s+(.*)$');
final RegExp _checkboxPattern = RegExp(r'^\s*-\s*\[( |x|X)\]\s*(.*)$');

/// [_checkboxPattern]'s capture-group index for the checkbox's item text
/// (group 1 is the `x`/`X`/space mark).
const int _checkboxTextGroup = 2;

/// Returns the text of every unchecked (`- [ ]`) item under the issue
/// body's `## Acceptance criteria` heading (case-insensitive, any heading
/// level), stopping at the next heading. Returns an empty list if the
/// section is absent or every item is checked.
List<String> uncheckedAcceptanceCriteria(String issueBody) {
  final unchecked = <String>[];
  var inSection = false;

  for (final line in issueBody.split('\n')) {
    final heading = _headingPattern.firstMatch(line);
    if (heading != null) {
      inSection =
          (heading.group(1) ?? '').trim().toLowerCase() ==
          'acceptance criteria';
      continue;
    }
    if (!inSection) continue;

    final checkbox = _checkboxPattern.firstMatch(line);
    if (checkbox == null) continue;
    if ((checkbox.group(1) ?? '').toLowerCase() != 'x') {
      unchecked.add((checkbox.group(_checkboxTextGroup) ?? '').trim());
    }
  }

  return unchecked;
}
