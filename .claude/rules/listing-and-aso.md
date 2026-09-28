---
paths:
  - "fastlane/**/*"
  - "project-docs/marketing/aso-plan.md"
  - "scripts/asc-upload-localizations.py"
  - "scripts/asc-rename-plus-branding.py"
  - "scripts/asc-setup-subscriptions.py"
  - "scripts/asc-setup-lifetime-iap.py"
  - "scripts/asc-readiness.py"
  - "scripts/upload-appstore-metadata.sh"
  - "scripts/pull-appstore-metadata.sh"
---

# Protein: listing, ASO, product names and localizations

Moved verbatim from AGENTS.md. Loads when a matching file is read; update it here.

### Subtitle and keyword rules

- The subtitle is **not** where the Watch story goes. Every watch term measured
  at Astro's floor (`protein watch` 5, `protein widget` 5, `apple watch food` 5
  at difficulty 72), fleet-wide, so a Watch-first subtitle spends 30 characters
  on zero demand; and `Apple Watch` is an Apple trademark that metadata rules
  keep out of the name and subtitle. The shipped `on Watch` says it safely.
  `glp1` stays out of the keyword field for the same floor-demand reason.
  Shipped name/subtitle/keywords and the full rationale: `project-docs/marketing/aso-plan.md` §7.
- **The subtitle's job is the `track` token** (changed 2026-08-16, all 50
  locales). `Daily intake goal, on Watch` became `Track daily intake on Watch`,
  same 27 characters. Nothing in the metadata carried the bare `track`, only
  `Tracker` in the name, so `track protein` (19/46), the realistic near-term
  rank, and the only above-floor protein term besides the guarded head, was
  plausibly unindexed. `goal` was floor and `target` covers it from the keyword
  field. Do not spend the subtitle on floor-demand nouns again.
- **The keyword field is full and should stay as it is.** Every above-floor,
  intent-passing term is covered; `whey protein` measured 9/11 in 2026-08-16 and
  justifies `whey`. `bodybuilding` (24/58) is the one that keeps looking like a
  gap and is not: its SERP is workout apps top to bottom, so it fails the §2
  intent guardrail. The only open question is `healthkit`, 9 characters and never
  measured. Measure before trading anything.

## Protein+, never "Protein Plus", anywhere a customer can read it (2026-08-15)

The App Store product names said **Protein Plus** in 49 of 50 locales: the group
name, `Protein Plus Monthly`, `Protein Plus Yearly`, `Protein Plus Lifetime`.
Only en-US was branded, because `fastlane/metadata/en-US/products.json` is the
only localized products file and both setup scripts fell back to the ASC
*reference* name for every locale without one. Those names are what the purchase
sheet and Settings › Apple ID › Subscriptions show, so a German buyer saw a
different product than the app, the paywall, the website, and the description.

`scripts/asc-rename-plus-branding.py` fixed all 196 localizations and is
idempotent; the two setup scripts now fall back to `GROUP_DISPLAY_NAME` /
`PRODUCT_DISPLAY_NAME` instead of the reference name. **Reference names stay
spelled out** — they are immutable after creation and ASC-internal.

The rename needed the products **out of the staged review submission first**.
Every localization of a queued product is frozen: ASC answers 409
`ENTITY_ERROR.ATTRIBUTE.INVALID.UNMODIFIABLE` on the name *and* on the
description, while the app version next to it stays fully editable. Deleting the
`reviewSubmissionItems` unfreezes them and leaves the version, its attached
build, and the products' `READY_TO_SUBMIT` state untouched. Do product metadata
before queueing, not after.

## The listing speaks 50 languages; the app speaks one (2026-08-16)

Protein shipped its first metadata in en-US only, and was the only app in the
fleet doing so: VO2 Max, Simple GLP, and Sober all carry 50 translated
`appStoreVersionLocalizations` and 50 `appInfoLocalizations`. Forty-nine empty
keyword fields, at 100 characters each, is the part that costs something, in an
app where `project-docs/marketing/aso-plan.md` already calls keyword volume the binding constraint.

`fastlane/metadata/<locale>/` now holds name, subtitle, keywords, description,
promo text, and release notes for all 50, pushed by
**`scripts/asc-upload-localizations.py`**. Two things that script does on
purpose:

- **It never touches `appScreenshotSets`.** Screenshots live on en-US and every
  other storefront falls back to them, which is the fleet shape (VO2 Max has
  sets on 1 of its 50). Running fastlane deliver instead would walk the
  screenshot tree and has double-uploaded a set on retry.
- **It re-reads before creating a version localization.** Adding a language to
  the app info *also* creates that locale's version localization, so a create
  built from a map read seconds earlier answers 409
  `ENTITY_ERROR.ATTRIBUTE.INVALID.DUPLICATE`.

Product names and descriptions stay English in all 50 (`Protein+ Monthly`,
"Monthly access to Protein+."), matching VO2+ and the rest of the fleet.

`asc-readiness.py` had to change with it. It now folds the per-localization
checks into one row per field instead of printing 50 near-identical lines, and
the subscription-disclosure check only looks for the four English phrases in
`en-*`. Apple wants those terms in each storefront's own language, so elsewhere
it asserts what survives translation: `24`, the EULA link, and the privacy link.

**The app itself is still English-only** and is not one string file away from
being otherwise. `knownRegions` is `(Base, en)`, and every number-bearing string
is built by interpolation in `ProteinFormat` and returned as `String`, so
`Text(_:)` never sees a `LocalizedStringKey` — the hero lines on the phone, the
watch, both widgets, and all four complications are invisible to a String
Catalog until they are restructured. Dates, percentages, and the preset list do
go through Foundation formatters and are already locale-correct. The one real
bug underneath this, onboarding printing a body weight in kg to everyone
including the US, went away with the body-weight change ("Body weight is typed, not read from Health" in `onboarding-and-targets.md`).
