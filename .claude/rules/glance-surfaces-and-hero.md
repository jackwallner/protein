---
paths:
  - "ProteinWatch/**/*.swift"
  - "ProteinWatchWidget/**/*.swift"
  - "ProteinWidget/**/*.swift"
  - "Shared/Utilities/ProteinFormat.swift"
  - "Protein/Views/TodayView.swift"
  - "Protein/Views/Components/ProgressRing.swift"
  - "Shared/Services/NotificationService.swift"
  - "ProteinTests/ProteinFormatTests.swift"
---

# Protein: the watch, widgets, complications and the hero number

Moved verbatim from AGENTS.md. Loads when a matching file is read; update it here.

### Watch layout and the complication glyph

- Watch layout must fit above the fold on a 41mm (224pt) screen. There is no
  navigation title for exactly this reason, and Undo takes the "Other" slot
  rather than adding a fourth row. Two more rules, both learned by rendering it
  (2026-08-13): **the ring holds the number and nothing else** (a circle's
  usable width collapses either side of its centre, so a caption stacked under
  the number sits where there is least room and runs into the stroke), and
  **the ring's ZStack is explicitly square**. A `Circle` stays 88pt on any
  watch, but a text stack sharing that ZStack takes the full screen width, so
  a caption that fits a 42mm overhangs the arc on a 46mm. The words go under
  the ring, on one line, where the screen is rectangular.
  `ProteinFormat.compactTargetCaption` is the wrist-sized `targetCaption`.
- The pool has no 41/42mm watch (`agent-sim checkout --watch` hands out a 46mm
  Series 11 or a 44mm SE). Verifying the fold means creating a throwaway
  `Apple-Watch-Series-11-42mm` device, screenshotting it headlessly, and
  deleting it. Do that for any change to the watch's vertical rhythm.

- **The complication and widget glyph is the app's own mark, a `g`**, not
  `bolt.fill` (changed 2026-08-13). The app icon is a lowercase g in a progress
  ring, so the bolt matched nothing; worse, watchOS spends `bolt.fill` on
  charging, so it read as a battery indicator on the one surface that sits
  beside real system glyphs. In a gauge the label is `Text("g")` under the
  value, which also just reads as the unit ("124 g"); the inline family needs a
  symbol, so it uses `g.circle.fill` (watchOS 6+). The bolt stays inside the
  app, where it decorates quick-add and Protein+ rather than identifying it.

## The hero is grams tracked, not grams left (2026-08-13)

Every surface leads with the grams logged so far today, counting up, with the
target as the caption under it: `124` / `grams tracked` / `of 160 g target`.
It replaced a countdown (`36` / `grams left`) on the phone hero, the watch
hero, both widget families, all four complication families, the evening
reminder, and the App Store name and copy.

A countdown has two problems the total does not. It has to clamp at zero, so
`ProteinFormat` needed a signed-overage variant for every slot too small for a
caption, and 160 of 160 read exactly like 185 of 160 anywhere that clamp
showed. And it describes the day as a deficit right up until the last bite,
which is the wrong frame for an app whose whole premise is that you logged.

`ProteinReconciliation.remaining` still exists and is still tested (it is the
arithmetic behind "of 160 g target"), but nothing renders it any more. The
formatter entry points are `trackedHeadline`, `compactTracked`,
`targetCaption`, and `gaugeValue`/`gaugeGrams`, and the last two dropped their
`target:` argument, because a total needs no target to stay honest.
