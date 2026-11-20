// Test literals (limits, windows, status codes) and `!` on a value the test
// just made are plain in a test and read worse as named constants.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_non_null_assertion, solid_lints/prefer_match_file_name

import 'package:api/src/rate_limit/rate_limit_store.dart';
import 'package:api/src/retention/retention_store.dart';
import 'package:api/src/schedule/slot_store.dart';

/// A [SlotStore] holding the (job, slot) pair unique, like the table.
class InMemorySlotStore implements SlotStore {
  /// The claimed `name#slot` keys.
  final Set<String> claimed = <String>{};

  @override
  Future<bool> claim(String jobName, int slot, DateTime now) async {
    await Future<void>.delayed(Duration.zero);

    return claimed.add('$jobName#$slot');
  }

  @override
  Future<void> release(String jobName, int slot) async {
    claimed.remove('$jobName#$slot');
  }
}

/// A [RateLimitStore] holding (key, window, hit) unique, like the table.
class InMemoryRateLimitStore implements RateLimitStore {
  /// Every stored row: `keyHash|windowStart|hit` mapped to its expiry.
  final Map<String, DateTime> rows = <String, DateTime>{};

  @override
  Future<int> hitsIn(String keyHash, int windowStart) async {
    await Future<void>.delayed(Duration.zero);

    return rows.keys
        .where((k) => k.startsWith('$keyHash|$windowStart|'))
        .length;
  }

  @override
  Future<bool> tryTake(
    String keyHash,
    int windowStart,
    int hit,
    DateTime expiresAt,
  ) async {
    await Future<void>.delayed(Duration.zero);
    final key = '$keyHash|$windowStart|$hit';
    if (rows.containsKey(key)) return false;
    rows[key] = expiresAt;

    return true;
  }
}

/// A [RetentionStore] over named tables of timestamped rows.
class InMemoryRetentionStore implements RetentionStore {
  /// `table` mapped to its rows' timestamps.
  final Map<String, List<DateTime>> tables = <String, List<DateTime>>{};

  @override
  Future<int> deleteOlderThan({
    required String table,
    required String column,
    required DateTime cutoff,
  }) async {
    final rows = tables[table] ?? <DateTime>[];
    final before = rows.length;
    rows.removeWhere((time) => time.isBefore(cutoff));

    return before - rows.length;
  }
}
