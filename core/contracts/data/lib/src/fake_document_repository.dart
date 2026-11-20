import 'package:data/src/data_error.dart';
import 'package:data/src/data_filter.dart';
import 'package:data/src/data_query.dart';
import 'package:data/src/document.dart';
import 'package:data/src/document_repository.dart';
import 'package:data/src/document_scope.dart';
import 'package:teams/teams.dart';

/// A stored row: its fields plus who may touch it.
class _Row {
  _Row(this.data, this.ownerUserId, this.scope, [this.revision = 1]);

  /// Bumped by every write: the fake's `Document.version`.
  final int revision;

  final Map<String, dynamic> data;
  final String? ownerUserId;
  final DocumentScope scope;
}

/// The next fake document ID number; shared by views of one collection.
class _IdSequence {
  int _next = 0;

  int next() => _next++;
}

/// An in-memory [DocumentRepository] for screens and tests.
///
/// One instance holds one collection's worth of documents. Set
/// `authenticated` to false to simulate a signed-out user for testing
/// error handling, without needing a real `FakeAuthService` wired in.
///
/// **Visibility.** Built with no `userId` it is the original single-user
/// fake: every document is visible to the one caller. Built with a `userId`
/// it mirrors what Appwrite computes itself, so tests catch a cross-tenant
/// leak: a [UserScope] document is visible to its creator only, a
/// [TeamScope] one to members of that team holding a role in its read set
/// (membership comes from `teams`, normally a `FakeTeamBackend`). Several
/// users over the same data are views of one collection, made with
/// [asUser].
class FakeDocumentRepository implements DocumentRepository {
  /// Creates an empty in-memory collection.
  ///
  /// With [userId] set, the repository acts as that user and enforces
  /// scopes; [teams] is then required to create or see a team-scoped
  /// document. [ownerColumn] and [teamColumn] are written into every
  /// created row, like `AppwriteDocumentRepository` does.
  FakeDocumentRepository({
    this.userId,
    this.teams,
    this.authenticated = true,
    this.ownerColumn = 'userId',
    this.teamColumn = 'teamId',
  }) : _rows = <String, _Row>{},
       _ids = _IdSequence();

  FakeDocumentRepository._shared(FakeDocumentRepository other, this.userId)
    : authenticated = other.authenticated,
      teams = other.teams,
      ownerColumn = other.ownerColumn,
      teamColumn = other.teamColumn,
      _rows = other._rows,
      _ids = other._ids;

  /// Whether calls should succeed as a signed-in user. Flip to false to
  /// make every method throw [DataUnauthenticatedError].
  bool authenticated;

  /// The user this repository acts as; null for the legacy single-user mode
  /// where nothing is scoped.
  final String? userId;

  /// Team membership, for team scopes.
  final TeamDirectory? teams;

  /// The column the creator's user ID is written to.
  final String ownerColumn;

  /// The column a team-scoped row's team ID is written to.
  final String teamColumn;

  final Map<String, _Row> _rows;
  // One sequence shared by every `asUser` view, so their IDs never collide.
  final _IdSequence _ids;

  /// The same collection, seen by another user: shares every row, so two
  /// users of one `FakeDocumentRepository` exercise cross-user visibility
  /// the way two sessions of one Appwrite table would.
  FakeDocumentRepository asUser(String userId) =>
      FakeDocumentRepository._shared(this, userId);

  @override
  Future<Document> create(
    Map<String, dynamic> data, {
    String? id,
    DocumentScope scope = const UserScope(),
  }) async {
    _requireAuthenticated();
    final resolvedId = id ?? 'fake-doc-${_ids.next()}';
    final user = userId;
    if (scope is TeamScope) await _requireCanScopeTo(user, scope);
    final stored = <String, dynamic>{
      ...data,
      ownerColumn: ?user,
      if (user != null && scope is TeamScope) teamColumn: scope.teamId,
    };
    final row = _Row(stored, user, scope);
    _rows[resolvedId] = row;

    return _toDocument(resolvedId, row);
  }

  @override
  Future<Document> read(String id) async {
    _requireAuthenticated();
    final row = _require(id);
    await _requireReadable(row);

    return _toDocument(id, row);
  }

  @override
  Future<List<Document>> query([
    DataQuery query = const DataQuery(),
    DocumentScope scope = const UserScope(),
  ]) async {
    _requireAuthenticated();

    final visible = <MapEntry<String, _Row>>[];
    for (final entry in _rows.entries) {
      if (await _inQueryScope(entry.value, scope)) visible.add(entry);
    }
    var results = visible
        .where(
          (entry) => query.filters.every((f) => _matches(f, entry.value.data)),
        )
        .map((entry) => _toDocument(entry.key, entry.value))
        .toList();

    final orderByField = query.orderByField;
    if (orderByField != null) {
      results.sort(
        (a, b) => Comparable.compare(
          a.data[orderByField] as Comparable<dynamic>,
          b.data[orderByField] as Comparable<dynamic>,
        ),
      );
      if (query.orderDescending) results = results.reversed.toList();
    }

    final limit = query.limit;
    if (limit != null && results.length > limit) {
      results = results.sublist(0, limit);
    }

    return results.toList();
  }

  @override
  Future<Document> update(
    String id,
    Map<String, dynamic> data, {
    String? expectedVersion,
  }) async {
    _requireAuthenticated();
    final row = _require(id);
    await _requireWritable(row);
    if (expectedVersion != null && expectedVersion != '${row.revision}') {
      throw DataConflictError(
        'Document "$id" changed since version $expectedVersion.',
      );
    }
    final stored = <String, dynamic>{
      ...data,
      // The scope columns are the backend's, not the caller's.
      for (final key in <String>[ownerColumn, teamColumn])
        if (row.data.containsKey(key)) key: row.data[key],
    };
    final updated = _Row(stored, row.ownerUserId, row.scope, row.revision + 1);
    _rows[id] = updated;

    return _toDocument(id, updated);
  }

  @override
  Future<void> delete(String id) async {
    _requireAuthenticated();
    final row = _require(id);
    await _requireWritable(row);
    _rows.remove(id);
  }

  Document _toDocument(String id, _Row row) => Document(
    id: id,
    data: Map<String, dynamic>.of(row.data),
    version: '${row.revision}',
  );

  bool _matches(DataFilter filter, Map<String, dynamic> data) =>
      switch (filter) {
        EqualsFilter(:final field, :final value) => data[field] == value,
      };

  _Row _require(String id) {
    final row = _rows[id];
    if (row == null) {
      throw DataNotFoundError('No document with id "$id".');
    }

    return row;
  }

  Future<Set<String>> _rolesIn(String user, String teamId) async {
    final directory = teams;
    if (directory == null) return const <String>{};

    return await directory.rolesOf(userId: user, teamId: teamId);
  }

  /// Whether [user] holds any of [roles] in [teamId]; null roles mean
  /// "every member", which every member's implied roles include.
  Future<bool> _holdsAny(String user, String teamId, Set<String>? roles) async {
    final held = await _rolesIn(user, teamId);

    return held.any(
      (r) => (roles ?? const <String>{TeamRoles.member}).contains(r),
    );
  }

  /// Appwrite only lets a creator grant roles they hold themselves.
  Future<void> _requireCanScopeTo(String? user, TeamScope scope) async {
    if (user == null) {
      throw const DataPermissionError('A team scope needs a signed-in user.');
    }
    final held = await _rolesIn(user, scope.teamId);
    final wanted = <String>{
      ...?scope.readRoles,
      ...?scope.writeRoles,
      if (scope.readRoles == null && scope.writeRoles == null) TeamRoles.member,
    };
    if (held.isEmpty || !wanted.every(held.contains)) {
      throw const DataPermissionError(
        'The creator must hold every role a team scope names.',
      );
    }
  }

  Future<bool> _canRead(_Row row) async {
    final user = userId;
    if (user == null) return true;
    final scope = row.scope;

    return switch (scope) {
      UserScope() => row.ownerUserId == user,
      TeamScope() => await _holdsAny(user, scope.teamId, scope.readRoles),
    };
  }

  Future<bool> _canWrite(_Row row) async {
    final user = userId;
    if (user == null) return true;
    final scope = row.scope;

    return switch (scope) {
      UserScope() => row.ownerUserId == user,
      TeamScope() => await _holdsAny(
        user,
        scope.teamId,
        scope.writeRoles ?? scope.readRoles,
      ),
    };
  }

  Future<bool> _inQueryScope(_Row row, DocumentScope scope) async {
    if (!await _canRead(row)) return false;
    if (userId == null) return true;

    return switch (scope) {
      UserScope() => row.ownerUserId == userId,
      TeamScope(:final teamId) =>
        row.scope is TeamScope && (row.scope as TeamScope).teamId == teamId,
    };
  }

  Future<void> _requireReadable(_Row row) async {
    if (!await _canRead(row)) {
      throw const DataPermissionError('This document is not yours to read.');
    }
  }

  Future<void> _requireWritable(_Row row) async {
    await _requireReadable(row);
    if (!await _canWrite(row)) {
      throw const DataPermissionError('This document is not yours to change.');
    }
  }

  void _requireAuthenticated() {
    if (!authenticated) {
      throw const DataUnauthenticatedError('No current user.');
    }
  }
}
