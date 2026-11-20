import 'package:data/data.dart';
import 'package:test/test.dart';

void main() {
  group('FakeDocumentRepository create/read', () {
    test('generates an id when none is given', () async {
      final repo = FakeDocumentRepository();

      final doc = await repo.create(<String, dynamic>{'name': 'Ada'});

      expect(doc.id, isNotEmpty);
      expect(doc.data['name'], 'Ada');
      expect(await repo.read(doc.id), isA<Document>());
    });

    test('honors an explicit id', () async {
      final repo = FakeDocumentRepository();

      final doc = await repo.create(<String, dynamic>{'name': 'Ada'}, id: 'a1');

      expect(doc.id, 'a1');
    });

    test('read throws DataNotFoundError for a missing id', () {
      final repo = FakeDocumentRepository();

      expect(() => repo.read('missing'), throwsA(isA<DataNotFoundError>()));
    });

    test('every method throws DataUnauthenticatedError when signed out', () {
      final repo = FakeDocumentRepository(authenticated: false);

      expect(
        () => repo.create(<String, dynamic>{}),
        throwsA(isA<DataUnauthenticatedError>()),
      );
      expect(() => repo.read('x'), throwsA(isA<DataUnauthenticatedError>()));
      expect(repo.query, throwsA(isA<DataUnauthenticatedError>()));
    });
  });

  group('FakeDocumentRepository update/delete', () {
    test('update replaces the document data', () async {
      final repo = FakeDocumentRepository();
      final created = await repo.create(<String, dynamic>{'name': 'Ada'});

      final updated = await repo.update(created.id, <String, dynamic>{
        'name': 'Grace',
      });

      expect(updated.data['name'], 'Grace');
      expect((await repo.read(created.id)).data['name'], 'Grace');
    });

    test('update throws DataNotFoundError for a missing id', () {
      final repo = FakeDocumentRepository();

      expect(
        () => repo.update('missing', <String, dynamic>{}),
        throwsA(isA<DataNotFoundError>()),
      );
    });

    test('delete removes the document', () async {
      final repo = FakeDocumentRepository();
      final created = await repo.create(<String, dynamic>{'name': 'Ada'});

      await repo.delete(created.id);

      expect(() => repo.read(created.id), throwsA(isA<DataNotFoundError>()));
    });

    test('delete throws DataNotFoundError for a missing id', () {
      final repo = FakeDocumentRepository();

      expect(() => repo.delete('missing'), throwsA(isA<DataNotFoundError>()));
    });
  });

  group('FakeDocumentRepository query', () {
    Future<FakeDocumentRepository> seeded() async {
      final repo = FakeDocumentRepository();
      await repo.create(<String, dynamic>{'name': 'Ada', 'age': 30});
      await repo.create(<String, dynamic>{'name': 'Grace', 'age': 40});
      await repo.create(<String, dynamic>{'name': 'Grace', 'age': 20});

      return repo;
    }

    test('returns every document with the default query', () async {
      final repo = await seeded();
      const seededCount = 3;

      expect(await repo.query(), hasLength(seededCount));
    });

    test('filters with EqualsFilter', () async {
      final repo = await seeded();
      const graceCount = 2;

      final results = await repo.query(
        const DataQuery(filters: <DataFilter>[EqualsFilter('name', 'Grace')]),
      );

      expect(results, hasLength(graceCount));
      expect(results.every((d) => d.data['name'] == 'Grace'), isTrue);
    });

    test('orders by a field, ascending and descending', () async {
      final repo = await seeded();

      final ascending = await repo.query(const DataQuery(orderByField: 'age'));
      expect(ascending.map((d) => d.data['age']), <int>[20, 30, 40]);

      final descending = await repo.query(
        const DataQuery(orderByField: 'age', orderDescending: true),
      );
      expect(descending.map((d) => d.data['age']), <int>[40, 30, 20]);
    });

    test('limits the result count', () async {
      final repo = await seeded();
      const pageSize = 2;

      final results = await repo.query(const DataQuery(limit: pageSize));

      expect(results, hasLength(pageSize));
    });
  });

  group('FakeDocumentRepository optimistic concurrency', () {
    test('a stale expectedVersion is refused with DataConflictError and '
        'changes nothing', () async {
      final repo = FakeDocumentRepository();
      final created = await repo.create(<String, dynamic>{'name': 'Ada'});
      final read = await repo.read(created.id);

      // Two editors both read `read`; the first saves, the second is stale.
      final first = await repo.update(created.id, <String, dynamic>{
        'name': 'Grace',
      }, expectedVersion: read.version);

      await expectLater(
        repo.update(created.id, <String, dynamic>{
          'name': 'Hopper',
        }, expectedVersion: read.version),
        throwsA(isA<DataConflictError>()),
      );
      expect((await repo.read(created.id)).data['name'], 'Grace');

      // Re-reading gives the current version, which is accepted.
      final retried = await repo.update(created.id, <String, dynamic>{
        'name': 'Hopper',
      }, expectedVersion: first.version);
      expect(retried.data['name'], 'Hopper');
    });

    test(
      'a write changes the version; no expectedVersion always wins',
      () async {
        final repo = FakeDocumentRepository();
        final created = await repo.create(<String, dynamic>{'name': 'Ada'});
        final updated = await repo.update(created.id, <String, dynamic>{
          'name': 'Grace',
        });

        expect(updated.version, isNot(created.version));
        expect((await repo.read(created.id)).version, updated.version);
        expect((await repo.query()).single.version, updated.version);
      },
    );
  });
}
