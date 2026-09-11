---
paths:
  - "scripts/asc-*.py"
  - "scripts/rc-setup.py"
  - "scripts/testflight.sh"
  - "fastlane/Fastfile"
  - "Protein.storekit"
  - "Shared/Services/StoreService.swift"
---

# Protein: release and submission history

Moved verbatim from CLAUDE.md. Dated snapshots: verify against ASC and `scripts/asc-readiness.py` before trusting any state here. Loads when a matching file is read; update it here.

## Release state (2026-08-16)

The release audit is green (101 unit tests, all four targets). Release archive
build 20 is uploaded, VALID, attached to 1.0, and submitted for review. Build 19
was the first carrying the app's own privacy manifests.
`scripts/asc-readiness.py` reports the live state of everything below; run it
rather than trusting this list.

**Done:** (`asc-readiness.py` run 2026-08-16: **no gaps**, 5 iPhone and 5 Apple Watch screenshots, all three URLs 200)

- TestFlight build 20 is uploaded, VALID, and **attached** to the 1.0 version.
  A draft version keeps the build that was attached first, so this needs
  re-pointing after every upload: build 8 stayed attached for two days after
  logging went free, which left the description promising a free tap that the
  attached binary charged for. `asc-readiness.py` fails when the attached build
  is not the newest VALID one, so the drift shows up before a submission, and
  **`scripts/asc-attach-build.py` fixes it** — it waits out processing and
  re-points the draft version. Run it after every `testflight.sh`.
- ASC products are all in review (`WAITING_FOR_REVIEW`, `READY_TO_SUBMIT`
  before the submit): `.monthly` $5.99, `.yearly` $29.99
  (both with a 1-week free trial in 175 territories and the Vitals PPP
  overrides), `.pro.lifetime` $59.99. Repriced up from $1.99 / $14.99 / $29.99
  effective 2026-08-10, the day logging went free: the old rows are preserved
  for anyone already subscribed. Nothing in the app hardcodes a price, but the
  App Store description, `docs/index.html`, `Protein.storekit`, and
  `StoreService.fixtureProducts()` all restate them, and all four were stale
  until 2026-08-11. Check them against ASC after any price change.
- The ASC record is renamed **Protein Tracker - Grams Today** (subtitle "Track
  daily intake on Watch"), genre Health & Fitness, with description, keywords,
  promo text, all three URLs, 5 iPhone 6.9" screenshots and 5 Apple Watch Series 10 screenshots, App Store review notes,
  and the age-rating declaration (`healthOrWellnessTopics` true,
  `medicalOrTreatmentInformation` NONE — mirroring Total Calories).

- The repo is public at **github.com/jackwallner/protein** with Pages serving
  `main` `/docs`. The privacy, terms, and support URLs in the metadata all
  resolve 200.

**RevenueCat is wired (2026-08-05).** The `default` offering now returns all
three packages from the public SDK endpoint the app calls, so a device build
renders the paywall instead of "Protein+ Plans Unavailable".

The failure was never the App Store side. All three IAPs have been
READY_TO_SUBMIT throughout. The project had two apps, `Protein (App Store)` and
a `Test Store`, and every package was attached to a Test Store product with a
bare identifier (`monthly`, `yearly`, `lifetime`). There were **zero App Store
products** in the project. Asked with `X-Platform: ios`, RevenueCat filtered to
App Store products, found none in any package, and dropped all three, an empty
offering that looked like missing packages. The ASC API key being configured
does *not* import a catalogue; it resolves metadata for products you declare.

`scripts/rc-setup.py` created the three App Store products, attached them to the
`Protein+` entitlement, and attached each to its existing package. The Test
Store products stay attached alongside, which is what keeps paywall previews
working; iOS filters them out.

Two things worth knowing next time:

- **V2 secret keys are project-scoped.** Every other key on this machine (VO2
  Max, Bridge, Cribbage, Mahj, StatScout, Aging, Queasy, DreamCart) returns only
  its own project from `GET /v2/projects`. A new app needs a key minted in its
  own project: Dashboard → project → Project settings → API keys → **+ New** →
  Secret key, `project_configuration` read/write.
- The lifetime product lands as `non_renewing_subscription` rather than
  `non_consumable`, because that is what v2's `type: "one_time"` maps to. VO2
  Max and Bridge both look identical, so it is fleet-wide rather than a Protein
  bug, but it has never been confirmed against a real lifetime purchase.

The App Review notes were rewritten 2026-08-11 and amended 2026-08-12. They said
"PROTEIN+ ... unlocks logging" a day after the description started saying logging
is free, a contradiction sitting in the two documents a reviewer reads side by
side, and then said "thirty days of history" after history went unbounded. They
now lead with "logging is free, no reviewer action is needed to exercise the
core feature". Those notes live only in ASC, not in `fastlane/metadata`, so
nothing in the repo reminds you they went stale: re-read them after any change
to what is paid. There is no script; patch `/appStoreReviewDetails/{id}` with
`asc_lib` directly.

## Submitted for review (2026-08-16)

Review submission `58cc9187…` went in at 04:45 UTC on 2026-08-17 with five
items, all `WAITING_FOR_REVIEW`: version 1.0 with **build 20** attached, both
subscriptions, and the lifetime IAP. `scripts/asc-submit-for-review.py` does the
last two steps (add the version as a `reviewSubmissionItem`, then
`PATCH {"submitted": true}`); the products were queued by hand beforehand,
because the v1 endpoint this key can see still has no relationship for them.

Two things blocked the submit that nothing in the repo predicted:

- **`contentRightsDeclaration` on the app was `null`**, and Apple refuses to
  create the *version* item without it: 409
  `ENTITY_ERROR.ATTRIBUTE.REQUIRED`. It was recorded here as answered in the web
  UI on 2026-08-15, so the note was wrong, not the API. Set from a script:
  `PATCH /apps/{id}` with `DOES_NOT_USE_THIRD_PARTY_CONTENT`, which is the true
  answer for an app with no food database, no photos, and no licensed data.
  Unlike the other forms below, this one **is** readable, so check it rather
  than trusting a note.
- **The type digit in a review submission item's id means nothing you can rely
  on.** Items come back with every relationship empty for this key, and the ids
  decode to `<submission>|<type>|<uuid>`. A first pass read type 17 as the
  version, skipped the add, and the submit failed on a missing
  `appStoreVersionForReview`. The script now always attempts the add and treats
  a duplicate as success.

**Still outstanding, needing Jack:** a real purchase has never been made on a
device. The offering resolves, which is necessary and not sufficient;
sandbox-buy each of the three and confirm `Protein+` goes active. This did not
block submission, but it is the one part of the funnel nothing here has proven.

The App Privacy questionnaire, the DSA trader declaration, the Regulated Medical
Device answer (No), and the Paid Apps/tax/banking agreements were all completed
in the web UI on 2026-08-15. None of them is visible to `asc-readiness.py`; the
API cannot read any of those forms.

## Rejected 4.3, resubmitted 2026-09-01

Build 20 was rejected under **guideline 4.3 (spam)**: "similar binary, metadata,
and/or concept as apps submitted by other developers, with only minor
differences." Nothing in the binary changed for the resubmission. Four things
were wrong around it, and all four are fixed.

**The repo did not exist.** `~/protein` was renamed to `~/caffeine` in
`bed4b25` ("pivot protein tracker to caffeine planner"), which left this app
with a rejected 1.0 and no working tree. Restored from `cc976b4`, the commit
before the pivot, and pushed to github.com/jackwallner/protein.

**All three URLs 404'd**, which is an automatic 5.1.1 rejection on its own and
would have wasted the resubmission. Deleting the repo took the Pages site with
it. Pages is re-enabled on `main` `/docs`; privacy, support, marketing, and
terms all return 200. `asc-readiness.py` checks these, so run it before every
submit: it is the one gap the API cannot infer from the version record.

**Every product was available in zero territories.** The two subscriptions and
the lifetime IAP each read "0 of 175 countries or regions selected", the IAP
with **Remove from Sale** actively set, while all of them still reported
`READY_TO_SUBMIT` and `asc-readiness.py` reported no gaps. Prices were intact
(monthly $5.99, yearly $29.99, lifetime $59.99, with the PPP overrides), only
availability was wiped, most likely when the products were unstuck from the
August submission. A device build would have rendered a paywall with nothing
purchasable. **Availability is not visible to this API key** (`/v1/inAppPurchases/{id}/inAppPurchaseAvailability`
and `/v1/subscriptions/{id}/availableTerritories` both 404), so nothing in the
repo can catch this. Check it by eye in ASC after any product surgery.

**A subscription group is not a submittable item by itself.** Adding the group
left the submit button dead with "New subscription groups must be submitted
with an auto-renewable subscription from within that group". Each subscription
has to be added individually from its own page, so the submission carries five
items: the version, the group, both subscriptions, and the lifetime IAP.

The App Review notes now open with a **4.3 section** naming what is particular
to this app and where a reviewer sees it in under a minute (the Sources screen's
per-app HealthKit attribution, HealthKit as the store rather than a mirror,
target history, and the deliberate absence of a food database), and ask Apple to
name the app it was matched against. Notes cap at 4000 characters; the current
set is 3096. They live only in ASC, so re-read them after any change to what is
paid.

Submission `87df25c6` went in at 21:54 UTC on 2026-09-01, five items,
`WAITING_FOR_REVIEW`, build 20, manual release.

**RevenueCat moved to its own project.** `proj2da5e398` was renamed *Caffeine*
during the pivot and still holds both apps' products. Protein now points at
`proj6681ebb5` with public key `appl_afIOVjPptziekOgZJRrBVzuddka`;
`rc-setup.py` created the three products, the `Protein+` entitlement, and the
`default` offering with all three packages, verified through the public
offerings endpoint the app actually calls. The v2 API now **rejects
`is_current` on offering creation**, so marking the offering current is a
separate step.
