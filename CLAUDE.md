# Protein Tracker — Project Guide

Pure protein tracking: one gram target, one number, wrist-first. XcodeGen
project/scheme: `Protein`, sim lease owner `protein` (`protein-watch` for a
paired-watch lease).

## Tech Stack
- Swift 6 / SwiftUI (strict concurrency)
- HealthKit (`dietaryProtein`, read **and** write), SwiftData in an App Group,
  WidgetKit, WatchConnectivity
- XcodeGen (`project.yml`). Targets: iOS 17+, watchOS 10+
- RevenueCat, entitlement lookup key `Protein+` (same string as the branding)

## Targets / bundle IDs
- `Protein` — `com.jackwallner.protein`
- `ProteinWidget` — `com.jackwallner.protein.widget`
- `ProteinWatch` — `com.jackwallner.protein.watch`
- `ProteinWatchWidget` — `com.jackwallner.protein.watch.widget`
- `ProteinTests` — `com.jackwallner.protein.tests`
- App Group `group.com.jackwallner.protein`
- ASC record `6797089333`

## Architecture

**HealthKit is the single source of truth, including for our own entries.**
This is the one decision the rest of the app hangs off (`research/plan.md` §4):

```
log 30g on wrist  →  HKQuantitySample(.dietaryProtein, 30g, source = us)
today's total     =  sum of ALL dietaryProtein samples
                     WHERE source ∈ (us + user-selected external sources)
SwiftData         =  read-through cache, for the widgets/complication only
```

`ProteinReconciliation` is pure (no HealthKit, no SwiftUI) and carries the
multi-source rules. It is the only part verifiable without a real device and
two food loggers, so it is the part that is unit tested hard.

Key files:
- `Shared/Utilities/ProteinReconciliation.swift` — totals, per-source rows, duplicate risk
- `Shared/Services/HealthKitService.swift` — read/write/auth/observer/cache
- `Shared/Services/ProteinLogService.swift` — log, undo, write-denied fallback
- `Shared/Services/WatchSyncService.swift` — settings mirror, phone → watch
- `Shared/Utilities/ProteinTargets.swift` — the audience fork's target maths
- `Shared/Utilities/ProteinInsights.swift` — streaks, days on target, month-on-month
- `Shared/Services/TargetHistoryService.swift` — what a target change does to past days

## Rules that hold everywhere
Condensed from the deep notes below; the reasoning and the history behind each one live there.
- HealthKit is the store for our own entries too. WatchConnectivity carries settings only (target, presets, entitlement, excluded sources), phone → watch, never entries.
- The write-denied fallback (`LocalProteinEntry`, `retryPendingLocalEntries()`) ships in v1 and runs on both devices. Do not let it rot.
- Logging is free everywhere. `PlusFeature` in `PaywallView.swift` is the single source of truth for what Protein+ adds, and every pitch surface reads it.
- **Protein+**, never "Protein Plus", anywhere a customer can read it. ASC reference names stay spelled out (they are immutable).
- The listing speaks 50 languages; the app itself is English-only.
- Watch layout must fit above the fold on a 41mm screen. The pool has no 41/42mm watch, so verify with a throwaway `Apple-Watch-Series-11-42mm` device.
- Every executable carries its own `PrivacyInfo.xcprivacy`, excluded from the target's source path and re-added with `buildPhase: resources`.
- After every `testflight.sh`, run `scripts/asc-attach-build.py`: a draft version keeps the build that was attached first.
- App Review notes live only in ASC. Re-read them after any change to what is paid. Do product metadata before queueing a submission, because queued product localizations freeze.
- Product availability is invisible to this API key: check it by eye in ASC after any product surgery. Run `scripts/asc-readiness.py` before every submit.
- RevenueCat is project `proj6681ebb5`; `proj2da5e398` belongs to Caffeine now.

## Deep notes (load on demand)
These files load automatically when you read a file matching their `paths:`. Agents that do not auto-load rules (AGENTS.md readers) should open the file for the area they are touching. Record new area-specific learnings in the matching file, not here.

| File | Sections | Read when |
|---|---|---|
| `.claude/rules/healthkit-and-sync.md` | "Consequences, all deliberate" of HealthKit being the store | HealthKit reads and writes, the log fallback, watch settings sync |
| `.claude/rules/free-vs-plus-and-history.md` | Free vs Protein+ (history, quick-add, complication, tabs, target changes, access model) | The paywall, Protein+ tab, History, target history, StoreKit trial |
| `.claude/rules/onboarding-and-targets.md` | Reasons are multi-select; Body weight is typed, not read from Health | Onboarding, target maths, reasons |
| `.claude/rules/glance-surfaces-and-hero.md` | Watch layout and the complication glyph; The hero is grams tracked, not grams left | The watch app, widgets, complications, `ProteinFormat` |
| `.claude/rules/listing-and-aso.md` | Subtitle and keyword rules; Protein+, never "Protein Plus"; The listing speaks 50 languages | Metadata, localizations, product names, ASO |
| `.claude/rules/privacy-and-analytics.md` | Privacy manifests, and the analytics answer | `project.yml`, privacy manifests, paywall impressions, the App Privacy form |
| `.claude/rules/release-history.md` | Release state (2026-08-16); Submitted for review (2026-08-16); Rejected 4.3, resubmitted 2026-09-01 | Any ASC submission, RevenueCat setup, pricing, review notes |

## App-specific notes
- **Review funnel trigger**: the third distinct day the user hits their target
  (`ReviewPromptTracker.recordTargetHit`), never before. App Store ID 6797089333.
- **App Review 1.4.1**: the lifter / GLP-1 / post-bariatric stories stay "track
  the target you were given". Never "we set your medical target". Two unit tests
  (`testReasonCopyMakesNoMedicalClaims`, `testCombinedRationaleMakesNoMedicalClaims`)
  fail the build on treat/cure/diagnose/prescribe/prevent appearing in the
  audience copy, the second across all 16 reason combinations — keep it that way.
- **Positioning is anti-AI on purpose.** No photo estimation, no food database,
  no calories, no macros beyond protein. That is the product, not a backlog.
- Never put `calorie`, `macro`, `AI`, or `scanner` in the subtitle — those steer
  Apple toward difficulty 73-81 SERPs and contradict the position (`aso-plan.md` §5).
- `ScreenshotFixtures` (DEBUG) backs `-SeedScreenshotData` / `-ScreenshotTab N`
  / `-PaywallSnapshot`. `StoreService` hydrates the paywall on the simulator from
  StoreKit Testing, falling back to `TestStoreProduct` fixtures, so the real
  paywall renders headlessly without ever configuring the prod RevenueCat key.

## Open risks (carried from `research/plan.md` §8)
1. **The HealthKit import test has never been run on a real device.** Whether
   MacroFactor / Cronometer / MyFitnessPal actually write readable
   `dietaryProtein` is unverified. If they mostly do not, the Sources screen
   degrades to a near-empty list and the import claim has to come off the
   product page before submission.
2. Keyword volume is the binding constraint, not the build (`aso-plan.md`).
3. PROTEIN PAL is a registered mark. Only a Justia search was run, never a real
   USPTO clearance.

---
Shared iOS conventions (build, simulator, release/TestFlight, ASC key, signing,
review funnel, gotchas): always-loaded global CLAUDE.md + the `ios-dev` skill.
