---
paths:
  - "Shared/Services/HealthKitService.swift"
  - "Shared/Services/ProteinLogService.swift"
  - "Shared/Services/WatchSyncService.swift"
  - "Shared/Services/DataService.swift"
  - "Shared/Utilities/ProteinReconciliation.swift"
  - "Shared/Models/ProteinRecords.swift"
  - "Protein/Views/SourcesView.swift"
  - "ProteinWatch/App.swift"
  - "ProteinTests/ProteinReconciliationTests.swift"
---

# Protein: HealthKit as the store, and what follows from it

Moved verbatim from AGENTS.md. Loads when a matching file is read; update it here.

Consequences, all deliberate:
- **No WatchConnectivity queue for entries.** HealthKit syncs across the paired
  devices, so a wrist tap reaches the phone with no write ordering, no retry,
  and no "logged while the phone was asleep" case. WC carries *settings only*
  (target, presets, entitlement, excluded sources), phone → watch, via
  `applicationContext`. Exclusions belong on that list: HealthKit hands both
  devices the same samples, so a wrist that has not been told a source was
  switched off keeps summing it and disagrees with the phone all day.
- **Double counting is not a special case.** One sum over one source set.
- **Write auth can be denied**, and HealthKit says so honestly. `ProteinLogService`
  falls back to `LocalProteinEntry` rows, which are summed alongside the
  HealthKit samples and migrated in later by `retryPendingLocalEntries()`. This
  path ships in v1; do not let it rot. **Both devices run it**: the watch has its
  own App Group, so grams stranded there can only be rescued by the watch itself.
- Reads use an `HKSampleQuery` grouped by source, **not** a statistics
  collection — the Sources screen needs per-source grams *and* timestamps, and
  a statistics sum cannot answer "which app, and when".
