// Scroll-reveal + count-up motion — a tiny static script, not a Jaspr
// `@client` component: both effects are pure
// IntersectionObserver + DOM text-content updates with no Jaspr component
// state to hydrate or sync between server and client, so wiring a
// `@client` component (which pulls in jaspr's client-compilation
// pipeline, a JS bundle per component, and server/client build
// duplication) would add real build-pipeline weight for zero behavioural
// benefit over a plain `<script defer>` — a direct 1:1 port of the
// reference site's scripts/reveal.ts + scripts/count-up.ts to plain JS, since
// neither ever depended on a Dart/Jaspr API in the first place.
//
// Both effects are gated on `prefers-reduced-motion: no-preference` (the
// accessibility acceptance criterion): reveals show their final,
// already-visible state and the count-up prints its final number
// immediately, with no observation or animation frame work at all.
(function () {
  'use strict';

  var reducedMotion = window.matchMedia(
    '(prefers-reduced-motion: reduce)',
  ).matches;

  var STAGGER_STEP_MS = 70;
  var STAGGER_CAP_INDEX = 2;
  var REVEAL_ROOT_MARGIN = '0px 0px 200px 0px';

  function initScrollReveal() {
    var groups = document.querySelectorAll('[data-reveal-group]');
    groups.forEach(function (group) {
      var items = Array.prototype.slice.call(
        group.querySelectorAll('[data-reveal]'),
      );
      items.forEach(function (el, index) {
        var delay = Math.min(index, STAGGER_CAP_INDEX) * STAGGER_STEP_MS;
        el.style.transitionDelay = delay + 'ms';
      });
    });

    if (reducedMotion) {
      document.querySelectorAll('[data-reveal]').forEach(function (el) {
        el.classList.add('is-visible');
      });
      return;
    }

    var io = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add('is-visible');
            io.unobserve(entry.target);
          }
        });
      },
      { threshold: 0, rootMargin: REVEAL_ROOT_MARGIN },
    );

    document
      .querySelectorAll('[data-reveal]')
      .forEach(function (el) {
        io.observe(el);
      });
  }

  var COUNT_UP_DURATION_MS = 900;

  function easeOutExpo(t) {
    return t === 1 ? 1 : 1 - Math.pow(2, -10 * t);
  }

  function runCountUp(el, target) {
    var start = performance.now();
    function tick(now) {
      var elapsed = now - start;
      var progress = Math.min(elapsed / COUNT_UP_DURATION_MS, 1);
      var value = Math.round(target * easeOutExpo(progress));
      el.textContent = String(value);
      if (progress < 1) {
        requestAnimationFrame(tick);
      }
    }
    requestAnimationFrame(tick);
  }

  // The element's own server-rendered text is already the real, final
  // number (see `proof_section.dart`'s own doc comment) — with no JS at
  // all, that's what a sighted visitor sees, permanently. Under reduced
  // motion this function leaves it untouched (the `reducedMotion` guard
  // below returns before ever touching `textContent`); otherwise, the
  // element is reset to `'0'` only once it is actually about to animate
  // (right before `runCountUp` starts), not on page load — so a visitor
  // who never scrolls the stat into view still sees the real number the
  // whole time, not a `'0'` waiting to be counted up.
  function initCountUp() {
    var elements = document.querySelectorAll('[data-count-to]');
    if (elements.length === 0) return;

    if (reducedMotion) return;

    var io = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          // A freshly-`observe()`d target gets an initial synchronous-ish
          // callback reporting its current (not-yet-intersecting) state —
          // without this check the animation started immediately on
          // page load, regardless of scroll position (found while verifying the
          // "reset to 0 only when about to animate" fix).
          if (!entry.isIntersecting) return;
          var el = entry.target;
          var target = Number(el.dataset.countTo);
          if (!Number.isNaN(target)) {
            el.textContent = '0';
            runCountUp(el, target);
          }
          io.unobserve(el);
        });
      },
      { threshold: 0.5 },
    );

    elements.forEach(function (el) {
      io.observe(el);
    });
  }

  // Mobile nav toggle — ports the reference site's `Nav.astro` overlay script.
  // Runs regardless of `prefers-reduced-motion` (opening/closing the menu
  // is a state change, not decorative motion); only the overlay's own
  // opacity transition is disabled under reduced motion, in `site.css`.
  function initNavToggle() {
    var toggle = document.querySelector('.site-nav__toggle');
    var overlay = document.getElementById('nav-overlay');
    var closeBtn = overlay
      ? overlay.querySelector('.nav-overlay__close')
      : null;
    if (!toggle || !overlay || !closeBtn) return;

    var openLabel = toggle.dataset.openLabel || '';
    var closeLabel = toggle.dataset.closeLabel || '';
    var focusableSelector = 'a[href], button:not([disabled])';
    var lastFocused = null;

    function onKeydown(event) {
      if (event.key === 'Escape') {
        event.preventDefault();
        closeOverlay();
        return;
      }
      if (event.key !== 'Tab') return;
      var focusables = Array.prototype.slice.call(
        overlay.querySelectorAll(focusableSelector),
      );
      if (focusables.length === 0) return;
      var first = focusables[0];
      var last = focusables[focusables.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    }

    function openOverlay() {
      lastFocused = document.activeElement;
      overlay.classList.add('is-open');
      toggle.setAttribute('aria-expanded', 'true');
      toggle.setAttribute('aria-label', closeLabel);
      document.body.style.overflow = 'hidden';
      var firstFocusable = overlay.querySelector(focusableSelector);
      if (firstFocusable) firstFocusable.focus();
      document.addEventListener('keydown', onKeydown);
    }

    function closeOverlay() {
      overlay.classList.remove('is-open');
      toggle.setAttribute('aria-expanded', 'false');
      toggle.setAttribute('aria-label', openLabel);
      document.body.style.overflow = '';
      document.removeEventListener('keydown', onKeydown);
      (lastFocused || toggle).focus();
    }

    toggle.addEventListener('click', function () {
      if (overlay.classList.contains('is-open')) {
        closeOverlay();
      } else {
        openOverlay();
      }
    });
    closeBtn.addEventListener('click', closeOverlay);
    Array.prototype.forEach.call(
      overlay.querySelectorAll('a'),
      function (link) {
        link.addEventListener('click', closeOverlay);
      },
    );
  }

  // FAQ disclosure — ports the reference site's `scripts/faq-disclosure.ts`.
  // Native `<details>`/`<summary>` snap open/closed instantly (no CSS
  // transition can animate the browser's own content-display toggle), so
  // this intercepts the click, keeps `open` semantics intact for
  // assistive tech, and animates the answer's height via the Web
  // Animations API. Skipped entirely under reduced motion: the native
  // `<details>` toggle (and its CSS chevron fallback, see `site.css`'s
  // `.faq-item[open]` rule) is what runs instead, matching the reference site's
  // own reduced-motion behaviour and, incidentally, exactly what happens
  // if this script never loads at all (no-JS: still a fully working,
  // keyboard-operable disclosure, just without the animated height).
  var FAQ_DURATION_MS = 220;
  var FAQ_EASING = 'cubic-bezier(0.16, 1, 0.3, 1)';

  function animateFaqOpen(details, wrap) {
    details.open = true;
    details.classList.add('faq-item--expanded');
    var targetHeight = wrap.scrollHeight;
    wrap.style.overflow = 'hidden';
    var animation = wrap.animate(
      [{ height: '0px' }, { height: targetHeight + 'px' }],
      { duration: FAQ_DURATION_MS, easing: FAQ_EASING },
    );
    animation.onfinish = function () {
      wrap.style.overflow = '';
      wrap.style.height = '';
    };
  }

  function animateFaqClose(details, wrap) {
    details.classList.remove('faq-item--expanded');
    var startHeight = wrap.scrollHeight;
    wrap.style.overflow = 'hidden';
    var animation = wrap.animate(
      [{ height: startHeight + 'px' }, { height: '0px' }],
      { duration: FAQ_DURATION_MS, easing: FAQ_EASING },
    );
    animation.onfinish = function () {
      details.open = false;
      wrap.style.overflow = '';
      wrap.style.height = '';
    };
  }

  function initFaqDisclosure() {
    if (reducedMotion) return;

    Array.prototype.forEach.call(
      document.querySelectorAll('.faq-item'),
      function (details) {
        var summary = details.querySelector('summary');
        var wrap = details.querySelector('.faq-item__answer-wrap');
        if (!summary || !wrap) return;

        summary.addEventListener('click', function (event) {
          event.preventDefault();
          if (details.open) {
            animateFaqClose(details, wrap);
          } else {
            animateFaqOpen(details, wrap);
          }
        });
      },
    );
  }

  initScrollReveal();
  initCountUp();
  initNavToggle();
  initFaqDisclosure();
})();
