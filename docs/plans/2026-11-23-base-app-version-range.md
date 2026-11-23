Approved: Kamil Sacek, 2026-11-23

# Match Microsoft.Application by Major.Minor.Build, ignore the patch number

**Goal:** When releasing to a BC environment (e.g. `29.0.54011.55407`), Paket limits
`Microsoft.Application` to `<= 29.0.54011` (revision ignored). Before, it asked for `<= 29.0.54011.55407` and failed when the
feed only had `29.0.54011.55575`. Change class: patch. Risk class: R1.

**Approach**
1. Extract the version-constraint logic into a pure function `Get-BaseApplicationVersionConstraint`.
2. Specific build -> `<= Major.Minor.Build` (revision ignored). (Amended on the product owner's instruction: the first version of this plan said `>= M.m.B < M.m.(B+1)`; that was a wrong requirement.)
3. Short version (`29`, `29.0`) keeps the original `<= <version>`; `29.0.0` stays `< Major+1.0`; explicit constraint passes through unchanged.
   (Amended after approval on the product owner's instruction: the original `<= 29.0` behavior is correct.)
4. `Install-ALNugetPackageByPaket` calls the function; platform constraint (`~> Major`) is unchanged.

**Files:** `NVRAppDevOps/Get-BaseApplicationVersionConstraint.ps1` (new),
`NVRAppDevOps/Install-ALNugetPackageByPaket.ps1`, `Tests/Get-BaseApplicationVersionConstraint.Tests.ps1` (new).

**Tests (Pester):** regression for `29.0.54011.55407` -> `<= 29.0.54011`; `29.1.2.3` and `29.1.2.0` -> `<= 29.1.2`; three-part build; short `29.0` / `29` (`<=`), generic `29.0.0` (`< 30.0`);
explicit constraints pass through.

**Out of scope:** `ConvertTo-PaketDependencies`, `Invoke-PaketForAl`.
