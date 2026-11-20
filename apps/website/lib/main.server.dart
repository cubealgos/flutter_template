/// The entrypoint for the **server** environment — the only environment
/// this site ever runs in: `mode: static` (see pubspec.yaml's `jaspr:`
/// key) pre-renders every route declared in `app.dart`'s `Router` to a
/// static HTML file at `jaspr build` time; nothing here ships to the
/// browser as a persistent server.
///
// Excluded from dartdoc entirely — see dartdoc_options.yaml's own
// comment.
library;

import 'package:jaspr/server.dart';

import 'package:website/app.dart';
// This file is generated automatically by Jaspr, do not remove or edit.
import 'package:website/main.server.options.dart';
import 'package:website/src/site_constants.dart';

/// Runs the app in the server (pre-rendering) environment.
///
/// [Document] renders the root `<html>`/`<head>`/`<body>` shell; every
/// page then layers its own per-route `<title>`/meta/stylesheet links on
/// top via `Document.head`/`Document.html` (see `src/seo_head.dart`) —
/// this top-level `Document` only supplies the fallback title and the
/// generated/hand-authored CSS files every page shares.
void main() {
  Jaspr.initializeApp(options: defaultServerOptions);

  runApp(const Document(title: productName, body: App()));
}
