Approved: Kamil Sacek, 2026-11-23

# Match Microsoft.Application by Major.Minor.Build, ignore the patch number

**Goal:** When releasing to a BC environment (e.g. `29.0.54011.55407`), Paket looks for
`Microsoft.Application` `29.0.54011.*`. Before, it asked for `<= 29.0.54011.55407` and failed when the
feed only had `29.0.54011.55575`. Change class: patch. Risk class: R1.

**Approach**
1. Extract the version-constraint logic into a pure function `Get-BaseApplicationVersionConstraint`.
2. Specific build -> `>= Major.Minor.Build < Major.Minor.(Build+1)`.
3. Short version (`29`, `29.0`) keeps the original `<= <version>`; `29.0.0` stays `< Major+1.0`; explicit constraint passes through unchanged.
   (Amended after approval on the product owner's instruction: the original `<= 29.0` behavior is correct.)
4. `Install-ALNugetPackageByPaket` calls the function; platform constraint (`~> Major`) is unchanged.

**Files:** `NVRAppDevOps/Get-BaseApplicationVersionConstraint.ps1` (new),
`NVRAppDevOps/Install-ALNugetPackageByPaket.ps1`, `Tests/Get-BaseApplicationVersionConstraint.Tests.ps1` (new).

**Tests (Pester):** regression for `29.0.54011.55407`; three-part build; short `29.0` / `29` (`<=`), generic `29.0.0` (`< 30.0`);
explicit constraints pass through.

**Out of scope:** `ConvertTo-PaketDependencies`, `Invoke-PaketForAl`.
