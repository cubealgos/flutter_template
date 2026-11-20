import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tooling/src/web_smoke_static_paths.dart';

/// Serves a built web output directory (`apps/app/build/web` or
/// `apps/website/build/jaspr`) on a loopback-only, OS-assigned local port —
/// a plain `dart:io` [HttpServer], not Python's `http.server` or a
/// pub-hosted static-file package, per the issue's "no python, no new
/// heavy deps" constraint.
///
/// Request-to-file resolution is [resolveStaticRequestPath] (pure, its own
/// test); this class is the live wrapper around it.
class WebSmokeStaticServer {
  WebSmokeStaticServer._(this._server, this._rootDir);

  final HttpServer _server;
  final String _rootDir;

  /// The loopback base URL this server is reachable on, e.g.
  /// `http://127.0.0.1:54321`.
  String get baseUrl => 'http://${_server.address.address}:${_server.port}';

  /// Starts serving [rootDir] on a fresh OS-assigned loopback port.
  static Future<WebSmokeStaticServer> start(String rootDir) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final instance = WebSmokeStaticServer._(server, rootDir);
    unawaited(instance._serveForever());

    return instance;
  }

  Future<void> _serveForever() async {
    await for (final request in _server) {
      unawaited(_handle(request));
    }
  }

  Future<void> _handle(HttpRequest request) async {
    final relativePath = resolveStaticRequestPath(request.uri.path);
    final file = File(p.join(_rootDir, relativePath));
    if (!file.existsSync()) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();

      return;
    }
    request.response.headers.contentType = _contentTypeFor(relativePath);
    await request.response.addStream(file.openRead());
    await request.response.close();
  }

  /// Stops the server immediately, dropping any in-flight request.
  Future<void> close() => _server.close(force: true);
}

/// Content types for every extension `flutter build web` and `jaspr
/// build` emit — enough for a browser to execute/parse each resource
/// correctly (a wrong `text/plain` on `main.dart.js` makes Chrome refuse
/// to run it as a module in some configurations). A lookup table rather
/// than a `switch`, which past a handful of cases reads as a flat list of
/// mappings anyway and trips solid_lints' `cyclomatic_complexity` (one
/// decision path per `case`) for no real complexity.
final Map<String, ContentType> _contentTypesByExtension = {
  '.html': ContentType.html,
  '.js': ContentType('application', 'javascript', charset: 'utf-8'),
  '.mjs': ContentType('application', 'javascript', charset: 'utf-8'),
  '.json': ContentType.json,
  '.css': ContentType('text', 'css', charset: 'utf-8'),
  '.wasm': ContentType('application', 'wasm'),
  '.svg': ContentType('image', 'svg+xml'),
  '.png': ContentType('image', 'png'),
  '.ico': ContentType('image', 'x-icon'),
};

ContentType _contentTypeFor(String relativePath) {
  final ext = p.extension(relativePath);

  return _contentTypesByExtension[ext] ?? ContentType.binary;
}
