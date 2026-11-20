import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The `<main>` landmark element — `package:jaspr`'s `dom/html` set has no
/// typed wrapper for it (unlike `div`/`section`/`nav`/`header`/`footer`),
/// so this uses the same `Component.element` escape hatch `Document`
/// itself is built on.
Component mainTag(
  List<Component> children, {
  String? id,
  String? classes,
  Map<String, String>? attributes,
}) {
  return Component.element(
    tag: 'main',
    id: id,
    classes: classes,
    attributes: attributes,
    children: children,
  );
}

/// The `<address>` element, used on the legal pages for the registered
/// business address — no typed wrapper in `package:jaspr`'s `dom/html`
/// set, same as [mainTag].
Component addressTag(List<Component> children, {String? classes}) {
  return Component.element(
    tag: 'address',
    classes: classes,
    children: children,
  );
}

/// The `<noscript>` element, used in the document `<head>` to force
/// scroll-revealed content visible when JavaScript never runs — no typed
/// wrapper in `package:jaspr`'s `dom/html` set, same as [mainTag].
Component noscriptTag(List<Component> children) {
  return Component.element(tag: 'noscript', children: children);
}

/// A `<style>` element wrapping raw (unescaped) CSS [text] — no typed
/// wrapper in `package:jaspr`'s `dom/html` set, same as [mainTag]. Used
/// only for the small [noscriptTag] override below; every other style on
/// this site lives in `web/site.css`/`web/tokens.g.css`.
Component styleTag(String text) {
  return Component.element(tag: 'style', children: [RawText(text)]);
}
