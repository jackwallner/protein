---
paths:
  - "Protein/Views/OnboardingView.swift"
  - "Shared/Utilities/ProteinTargets.swift"
  - "Shared/Services/GoalSettings.swift"
  - "Shared/Services/HealthKitService.swift"
  - "ProteinTests/ProteinTargetsTests.swift"
---

# Protein: onboarding reasons and the target

Moved verbatim from AGENTS.md. Loads when a matching file is read; update it here.

### Reasons are multi-select

- **Reasons are multi-select** (2026-08-10). They stack in real life: a lifter on
  a GLP-1 is one person with one target. Any medical reason in the set means the
  number is entered, never inferred; otherwise the most demanding reason sets the
  suggestion. Stored as `reasons` (array of raw values), migrated from the old
  single `reason` key on first launch.

## Body weight is typed, not read from Health (2026-08-16)

"Suggest from my body weight" on the onboarding target step opens a field and an
lb/kg picker (`BodyWeightUnit.localeDefault`, pounds in the US and UK) rather
than reading `HKQuantityType(.bodyMass)`. The weight is converted and
range-checked by `ProteinTargets.bodyWeightKilograms(fromText:unit:)`, which
answers nil outside 25–300 kg so a typo suggests nothing rather than something
absurd.

What the Health read cost, all of it for one multiplication: a **second
permission sheet** mid-onboarding, before the app could answer at all; the
number printed in **kg to everyone** because the sample is stored in kg; and
nothing to say to the many people whose weight is not in Health, on a brand new
phone least of all. `requestBodyMassAuthorization` and `fetchBodyMassKilograms`
are gone from `HealthKitService`, the body-weight sentence is out of
`NSHealthShareUsageDescription`, and the privacy policy now says the app reads
no body weight. HealthKit access is dietary protein, read and write, and nothing
else.
