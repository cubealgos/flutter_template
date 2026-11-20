/// Maps an incoming HTTP request path to the file `WebSmokeStaticServer`
/// serves for it, relative to the static root it was started on.
///
/// `/` and any directory-style path (`/de/`) resolve to that directory's
/// `index.html` — the same convention every static host this repo targets
/// uses (`apps/website/build/jaspr/de/index.html` for route `/de/`,
/// `apps/app/build/web/index.html` for route `/`). Anything else is
/// served byte-for-byte, stripped of its leading slash. Pure (a string in,
/// a string out — no filesystem access), so it's exercised directly by
/// `web_smoke_static_paths_test.dart` without a real `HttpServer`; the
/// live lookup (`File(p.join(rootDir, resolveStaticRequestPath(...)))`)
/// lives in `web_smoke_static_server.dart` instead.
String resolveStaticRequestPath(String requestPath) {
  if (requestPath.isEmpty || requestPath == '/') return 'index.html';

  final withoutLeadingSlash = requestPath.startsWith('/')
      ? requestPath.substring(1)
      : requestPath;

  return withoutLeadingSlash.endsWith('/')
      ? '${withoutLeadingSlash}index.html'
      : withoutLeadingSlash;
}
