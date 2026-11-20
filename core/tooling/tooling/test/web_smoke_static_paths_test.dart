import 'package:test/test.dart';
import 'package:tooling/src/web_smoke_static_paths.dart';

void main() {
  test('root resolves to index.html', () {
    expect(resolveStaticRequestPath('/'), 'index.html');
  });

  test('empty path resolves to index.html', () {
    expect(resolveStaticRequestPath(''), 'index.html');
  });

  test('a directory-style path resolves to its own index.html', () {
    expect(resolveStaticRequestPath('/de/'), 'de/index.html');
  });

  test('a nested directory-style path resolves correctly', () {
    expect(
      resolveStaticRequestPath('/de/impressum/'),
      'de/impressum/index.html',
    );
  });

  test('a file path is served as-is, leading slash stripped', () {
    expect(resolveStaticRequestPath('/main.dart.js'), 'main.dart.js');
  });

  test('a nested file path is served as-is', () {
    expect(
      resolveStaticRequestPath('/canvaskit/canvaskit.wasm'),
      'canvaskit/canvaskit.wasm',
    );
  });
}
