import 'package:appwrite/appwrite.dart';
import 'package:appwrite_adapters/appwrite_adapters.dart';
import 'package:data/data.dart';
import 'package:test/test.dart';

void main() {
  group('buildAppwriteQueries', () {
    test('is empty for the default query', () {
      expect(buildAppwriteQueries(const DataQuery()), isEmpty);
    });

    test('maps an EqualsFilter to Query.equal', () {
      final queries = buildAppwriteQueries(
        const DataQuery(filters: <DataFilter>[EqualsFilter('name', 'Ada')]),
      );

      expect(queries, <String>[Query.equal('name', 'Ada')]);
    });

    test('maps orderByField ascending and descending', () {
      final ascending = buildAppwriteQueries(
        const DataQuery(orderByField: 'age'),
      );
      final descending = buildAppwriteQueries(
        const DataQuery(orderByField: 'age', orderDescending: true),
      );

      expect(ascending, <String>[Query.orderAsc('age')]);
      expect(descending, <String>[Query.orderDesc('age')]);
    });

    test('maps limit', () {
      const pageSize = 5;

      final queries = buildAppwriteQueries(const DataQuery(limit: pageSize));

      expect(queries, <String>[Query.limit(pageSize)]);
    });

    test('combines filters, order and limit in order', () {
      const pageSize = 10;

      final queries = buildAppwriteQueries(
        const DataQuery(
          filters: <DataFilter>[EqualsFilter('name', 'Ada')],
          orderByField: 'age',
          limit: pageSize,
        ),
      );

      expect(queries, <String>[
        Query.equal('name', 'Ada'),
        Query.orderAsc('age'),
        Query.limit(pageSize),
      ]);
    });
  });
}
