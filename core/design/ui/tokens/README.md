# Token source

Copied from a separate design-system repository's `tokens/*.json` on 2026-09-24. From that point
on these files are owned by this template — there is no link back, and a change to the original
tokens does not propagate here (a deliberate one-time copy, as opposed to a live dependency).

Edit these files directly to change a colour, a spacing value, a radius, a type size or a motion
curve, then run `melos run gen` (`core/design/tokens_builder` regenerates
`core/design/ui/lib/src/tokens.g.dart`). Never hand-edit `tokens.g.dart`.

## Files

DTCG (Design Tokens Community Group) format, `$value`/`$type`/`$description`, references as
`{a.b.c}`.

| File | Tier | Themed |
| --- | --- | --- |
| `color.light.json`, `color.dark.json` | primitive | light / dark |
| `dimension.json` | primitive (`stroke`, `radius`, `grid`, `space`) | no |
| `typography.json` | primitive (`font.family`, `product` role-named type ramp — the old `typography.*` composite diagram-label scale was dropped entirely) | no |
| `motion.json` | primitive (`motion.duration`, `motion.ease`) | no |
| `semantic.color.json` | semantic (`color.bg`/`fg`/`border`/…, aliases into `color.*`) | light / dark, each resolved against its own primitives |
| `semantic.motion.json` | semantic (`motion.duration.default`/`slow`, `motion.easing.*`, aliases into `motion.*`) | no — motion is not themed |

## Units

Read explicitly by the builder, never assumed — unlike Style Dictionary's flutter transform
group, which assumes `rem`: `px` passes through unchanged, `rem` is multiplied by 16, a bare unitless number passes
through unchanged, and `em` is only resolved inside a composite `typography.*` entry (relative to
that entry's own `font-size`, the one place `em` has a well-defined base in this token set) — any
other unit, or a bare `em` outside a composite entry, is a build error naming the offending token.
