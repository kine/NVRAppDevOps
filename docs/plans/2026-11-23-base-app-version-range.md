Approved: Kamil Sacek, 2026-11-23
Amended on the product owner's instruction (2026-11-23): the approach was narrowed to the one generated line, see "Amendments".

# Accept any Microsoft.Application build up to Major.Minor.Build.*

**Goal:** When releasing to a BC environment (e.g. `29.0.54011.55407`), Paket no longer writes
`nuget Microsoft_Application <= 29.0.54011.55407` (it failed when the feed only had `29.0.54011.55575`).
It writes `~> 29.0.54011.0 >= 1.0.0.0`: anything below `29.0.54011.*`+1, i.e. up to and including every
`29.0.54011.*`. Change class: patch. Risk class: R1.

**Approach**
1. Add a small pure function `Get-BaseApplicationBuildConstraint` -> `~> Major.Minor.Build.0 >= 1.0.0.0`.
2. In `Install-ALNugetPackageByPaket`, only the line generated for a specific build (Build > 0) uses it.
   Everything else (short versions `29` / `29.0` -> `<= <version>`, `29.0.0` -> `< Major+1.0`, explicit
   constraints, the platform line) is the original code, untouched.

**Files:** `NVRAppDevOps/Get-BaseApplicationBuildConstraint.ps1` (new),
`NVRAppDevOps/Install-ALNugetPackageByPaket.ps1` (one line), `Tests/Get-BaseApplicationBuildConstraint.Tests.ps1` (new).

**Tests (Pester):** the generated text for `29.0.54011.55407`, `29.0.54011`, `29.1.2.3`, `29.1.2.0`, `29.0.1`;
and, when `Paket.Core.dll` is available, the real Paket parser proves the meaning: `29.0.54011.55575` accepted,
`29.0.54012.0` and `29.1.0.0` rejected.

**Out of scope:** `ConvertTo-PaketDependencies`, `Invoke-PaketForAl`.

## Amendments
- The first versions generated `>= M.m.B < M.m.(B+1)`, then `<= M.m.B`. Checked with the real Paket parser:
  `<= 29.0.54011` does NOT admit `29.0.54011.55575` (it would not fix the bug).
- The suggested `~> 29.0.54011 >= 1.0.0.0` means `>= 1.0 < 29.1` in Paket (three segments chop the last one),
  which also admits `29.0.54012+`. The four-segment form `~> 29.0.54011.0` means `< 29.0.54012`, which matches the goal.
