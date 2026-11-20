import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tooling/src/map_generator.dart';

/// The exact file name solid_lints' `avoid_duplicate_code` rule persists its
/// cross-file duplicate-code index under, inside a `.dart_tool/solid_lints/`
/// directory. See [deleteStaleDuplicateIndexes]'s doc comment for why every
/// copy of this file is deleted before each `melos run analyze`.
const String duplicateIndexFileName = 'duplicate_index.json';

/// Deletes every `.dart_tool/solid_lints/duplicate_index.json` under
/// [repoRoot] — the workspace root itself, plus each workspace member
/// listed in its `pubspec.yaml` `workspace:` key (loaded the same way
/// `map`'s own [MapGenerator.loadMembers] does, so this never drifts from
/// what `map`/`map-check` already consider a member) — and returns the
/// paths deleted, relative to [repoRoot], for logging. A path with no file
/// on disk is silently skipped; only a file named exactly
/// [duplicateIndexFileName] directly under a `.dart_tool/solid_lints/`
/// directory is ever touched, never anything else under `.dart_tool/`.
///
/// ### Why this index has to be deleted, not just distrusted
///
/// solid_lints' `GlobalHashRegistry` (its cross-file clone-detection
/// singleton) loads this file once per analysis process and then persists
/// updates back to it on a 500ms debounce, per package root
/// (`_scheduleSave`/`_performSave` in
/// `solid_lints/lib/src/lints/avoid_duplicate_code/services/
/// global_hash_registry.dart`). A batch `dart analyze` run is short-lived,
/// so that debounce frequently loses the race against process exit —
/// confirmed by hand: on this workspace, repeated warm `dart
/// analyze` runs left the on-disk file byte-for-byte unchanged across
/// edits that should have updated it, while a single slow (~45s,
/// cold-plugin) full-workspace run did flush. The result is a cache that
/// can silently stop tracking reality for an unpredictable, possibly very
/// long time.
///
/// **False positive (confirmed, reproduces the original bug):** when a
/// function moves from file A to file B, and A's *stale* entry never got
/// overwritten on disk (the debounce-loss above), a fresh `dart analyze`
/// process loads that stale entry for A at startup. If B is analyzed
/// before A is re-analyzed within that process, `avoid_duplicate_code`
/// reports B as an "Exact duplicate" of A at A's *old* offset — even
/// though A's on-disk file still exists (so solid_lints' own
/// physical-file existence check, which does purge entries for *deleted*
/// files, doesn't catch this) and no longer contains that code. This was
/// reproduced by hand: seeding the index with a function's real hash
/// entry under file A, moving the function to file B without
/// re-priming, then running `dart analyze` — it fired on B referencing
/// A's stale offset; deleting the index first made it clean, with the
/// same two files on disk both times.
///
/// **False negative (also confirmed, a second and distinct mechanism):**
/// `GlobalHashRegistry` skips re-parsing a file entirely — replaying its
/// *cached* entries as-is — whenever the file's current OS modification
/// timestamp equals the timestamp recorded in the index
/// (`_tryReportFromCache`, keyed on `File.modificationStamp`, i.e. mtime
/// in milliseconds). Reproduced by hand: crafting a stale index entry for
/// a file with an empty candidate list and forcing that file's mtime
/// (`touch -t`) back to the exact value recorded in the index, then
/// editing the file's *content* to become an exact duplicate of another
/// file — `avoid_duplicate_code` reported nothing for either file, a real
/// duplicate silently masked, because the cache-hit path never looked at
/// the file's actual content again. A tool, a checkout, or a filesystem
/// that can reproduce an old mtime (not exercised here, but a real risk
/// class) would hit this same path. Deleting the index removes the stale
/// timestamp, so every file is always freshly parsed.
///
/// **Not a false-negative path, checked and ruled out:** a stale entry for
/// an unrelated, moved-away file does *not* mask detection of a genuinely
/// new, unrelated duplicate introduced elsewhere — confirmed by hand with
/// both present in the same run (the stale entry fired its own, separately
/// wrong report; the real new duplicate fired too). The registry's
/// cross-file index is an additive hash→locations map
/// (`SetDictionary`), so an extra stale location can only ever add a
/// spurious match, never suppress a distinct one.
List<String> deleteStaleDuplicateIndexes({required Directory repoRoot}) {
  final targetDirs = <Directory>[
    repoRoot,
    for (final member in MapGenerator(repoRoot: repoRoot).loadMembers())
      member.directory,
  ];

  final deleted = <String>[];
  for (final dir in targetDirs) {
    final indexFile = File(
      p.join(dir.path, '.dart_tool', 'solid_lints', duplicateIndexFileName),
    );
    if (indexFile.existsSync()) {
      indexFile.deleteSync();
      deleted.add(p.relative(indexFile.path, from: repoRoot.path));
    }
  }

  return deleted;
}
