---
paths:
  - "Protein/Views/PaywallView.swift"
  - "Protein/Views/PlusTabView.swift"
  - "Protein/Views/HistoryView.swift"
  - "Protein/Views/TrialOfferSheet.swift"
  - "Protein/Views/Components/PlusGate.swift"
  - "Protein/Views/SettingsView.swift"
  - "Shared/Services/StoreService.swift"
  - "Shared/Services/TargetHistoryService.swift"
  - "Shared/Utilities/ProteinInsights.swift"
  - "Shared/Utilities/ConversionCopy.swift"
  - "ProteinTests/TargetHistoryTests.swift"
  - "ProteinTests/ProteinInsightsTests.swift"
  - "ProteinTests/PaywallFunnelTests.swift"
---

# Protein: free vs Protein+, history, and target changes

Moved verbatim from CLAUDE.md. Loads when a matching file is read; update it here.

## Free vs Protein+

**Logging is free, everywhere** (decided 2026-08-10). Adding grams on the phone
and on the wrist, the three quick-add buttons, and any amount you like: all
free, along with the target, today's total imported from Apple Health, source
controls, the widget, the complication, and 7 days of history. An app whose
whole job is "tap a number" cannot charge before the first tap.

Protein+ is what a month of that adds up to: **every day you have logged**
(changed 2026-08-12 from a 30-day cap), streaks and month-on-month trends (the
Protein+ tab), setting the three quick-add buttons to your own amounts, and the
evening reminder. `PlusFeature` in `PaywallView.swift` is the single source of
truth for the list; every pitch surface reads it.

History is unbounded because HealthKit already stores it: `fetchFullHistory()`
queries ten years and trims the leading empty days, so the range starts when the
user did. The History screen offers 7 / 30 / 90 / All, and past 90 loaded days
the chart switches to a bar per week (`ProteinInsightsBuilder.weeks`) with
*averages*, because a weekly sum against a daily target line compares two
different units. The Protein+ tab still compares this month with the last one;
only Best streak reads the whole history.

The three quick-add buttons ship at 25/30/40 g and work for everyone. A lapsed
subscriber keeps whatever amounts they set — locking the editor is the gate, and
reverting their buttons would be a punishment for cancelling.

The complication keeps updating for free users on purpose. It costs nothing and
it is what keeps the app on the wrist while they reconsider; the graveyard
clones in `aso-plan.md` collect one-star reviews for taking everything away.

**Tabs are Today, History, Protein+, Settings.** The Protein+ tab is an embedded
paywall for free users (`impressionID: "protein_plus_tab"`) and the subscriber
hub otherwise, the same shape as VO2+ and Vitals+. Off-screen it renders
`Color.clear` so a paywall nobody opened logs no impression and puts nothing in
front of VoiceOver.

**Changing the target asks about the past.** History rows print the target that
was in force on the day, but a day the app never reconciled has no row and falls
back to the current target — so doing nothing is not neutral, and raising the
target silently turns a week of green days red. `TargetHistoryService` makes
both answers a write.

It stores a **change log** ("from this day forward, the target was N") in the
App Group defaults, not a row per day. Keeping the past appends one entry;
applying it collapses the log to a single all-time entry and rewrites the stored
rows. This replaced a 60-day window that materialized a `DailyProteinRecord` per
past day (2026-08-12): once history went unbounded, that meant inserting a row
for every day since install on every target change, and any day older than the
window silently inherited the new target. Stored rows still outrank the log —
they are what the day was actually reconciled against.

Access model: **one StoreKit trial**, decided 2026-08-04. The offer sheet is the
final onboarding step and StoreKit owns the 7 days. There is no separate local
trial window — `research/plan.md` §7 flagged the stacked alternative and it was
rejected.
