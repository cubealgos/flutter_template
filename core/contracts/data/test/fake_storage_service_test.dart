import 'dart:typed_data';

import 'package:data/data.dart';
import 'package:test/test.dart';

void main() {
  group('FakeStorageService upload/download', () {
    test('uploads and downloads the same bytes', () async {
      final storage = FakeStorageService();
      final bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);

      final stored = await storage.upload(fileName: 'avatar.png', bytes: bytes);
      final downloaded = await storage.download(stored.id);

      expect(stored.fileName, 'avatar.png');
      expect(stored.sizeBytes, bytes.length);
      expect(downloaded, bytes);
    });

    test('honors an explicit id', () async {
      final storage = FakeStorageService();

      final stored = await storage.upload(
        fileName: 'avatar.png',
        bytes: Uint8List(0),
        id: 'file-1',
      );

      expect(stored.id, 'file-1');
    });

    test('download throws DataNotFoundError for a missing id', () {
      final storage = FakeStorageService();

      expect(
        () => storage.download('missing'),
        throwsA(isA<DataNotFoundError>()),
      );
    });
  });

  group('FakeStorageService delete', () {
    test('removes the file', () async {
      final storage = FakeStorageService();
      final stored = await storage.upload(
        fileName: 'avatar.png',
        bytes: Uint8List(0),
      );

      await storage.delete(stored.id);

      expect(
        () => storage.download(stored.id),
        throwsA(isA<DataNotFoundError>()),
      );
    });

    test('throws DataNotFoundError for a missing id', () {
      final storage = FakeStorageService();

      expect(
        () => storage.delete('missing'),
        throwsA(isA<DataNotFoundError>()),
      );
    });
  });

  group('FakeStorageService authentication', () {
    test('every method throws DataUnauthenticatedError when signed out', () {
      final storage = FakeStorageService(authenticated: false);

      expect(
        () => storage.upload(fileName: 'x', bytes: Uint8List(0)),
        throwsA(isA<DataUnauthenticatedError>()),
      );
      expect(
        () => storage.download('x'),
        throwsA(isA<DataUnauthenticatedError>()),
      );
      expect(
        () => storage.delete('x'),
        throwsA(isA<DataUnauthenticatedError>()),
      );
    });
  });
}
