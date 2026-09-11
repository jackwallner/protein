---
paths:
  - "project.yml"
  - "Protein/PrivacyInfo.xcprivacy"
  - "ProteinWatch/PrivacyInfo.xcprivacy"
  - "ProteinWidget/PrivacyInfo.xcprivacy"
  - "ProteinWatchWidget/PrivacyInfo.xcprivacy"
  - "Shared/Services/StoreService.swift"
  - "docs/privacy-policy.html"
---

# Protein: privacy manifests and paywall impressions

Moved verbatim from CLAUDE.md. Loads when a matching file is read; update it here.

## Privacy manifests, and the analytics answer (2026-08-15)

**All four executables ship their own `PrivacyInfo.xcprivacy`.** Apple wants the
manifest in every binary that touches a required-reason API, not just the app,
and up to build 18 the archive carried only RevenueCat's. The only such API here
is `UserDefaults`: `CA92.1` for the app's own defaults and `1C8F.1` for the App
Group ones, which is what the widgets and the watch actually read, so both
reasons are declared in all four. Tracking is false, tracking domains and
collected data types are empty.

XcodeGen needs the file **excluded from the target's source path and re-added
with `buildPhase: resources`** (the fleet shape, see SimpleGLP). A manifest that
is only swept up by `- path: Protein` does not reliably land in the bundle, and
an archive that silently lacks it looks identical to one that has it.

**RevenueCat paywall impressions stay** (decided 2026-08-15). `StoreService.trackPaywallImpression`
reports three IDs — `protein_paywall`, `protein_plus_tab`, `protein_onboarding_trial`
— and the other fifteen apps in the fleet do the same, which is where the
impression and conversion numbers in the RC dashboard come from. The "no ads, no
analytics" line in the app, the site, and the description stays as written. The
residual: those calls are product-interaction events sent to a third party, so a
strict reading of Apple's App Privacy form wants Usage Data › Product
Interaction declared alongside Purchases. It is not declared. Revisit that
answer, not the code, if App Review ever asks.
