# Optional: the tests that prove the meaning of the constraint use the real Paket parser and are skipped
# when Paket.Core.dll is not available. Set PAKET_CORE_DIR to the folder containing Paket.Core.dll.
# Evaluated at discovery time, because -Skip below is.
$paketDir = if ($env:PAKET_CORE_DIR) { $env:PAKET_CORE_DIR } else { '\\lib\Templates\Paket' }
$paketAvailable = Test-Path (Join-Path $paketDir 'Paket.Core.dll')

BeforeAll {
    . (Join-Path $PSScriptRoot '..\NVRAppDevOps\Get-BaseApplicationBuildConstraint.ps1')

    $paketDir = if ($env:PAKET_CORE_DIR) { $env:PAKET_CORE_DIR } else { '\\lib\Templates\Paket' }
    if (Test-Path (Join-Path $paketDir 'Paket.Core.dll')) {
        Get-ChildItem $paketDir -Filter *.dll | ForEach-Object { try { [void][Reflection.Assembly]::LoadFrom($_.FullName) } catch { } }
    }
    function script:Test-PaketInRange([string]$Constraint, [string]$Version) {
        $requirement = [Paket.DependenciesFileParser]::parseVersionRequirement($Constraint)
        $requirement.IsInRange(([Paket.SemVer]::Parse).Invoke($Version), $null)
    }
}

Describe 'Get-BaseApplicationBuildConstraint' {
    It 'drops the revision and pins Major.Minor.Build: <Version>' -ForEach @(
        @{ Version = '29.0.54011.55407'; Expected = '~> 29.0.54011.0 >= 1.0.0.0' }
        @{ Version = '29.0.54011'; Expected = '~> 29.0.54011.0 >= 1.0.0.0' }
        @{ Version = '29.1.2.3'; Expected = '~> 29.1.2.0 >= 1.0.0.0' }
        @{ Version = '29.1.2.0'; Expected = '~> 29.1.2.0 >= 1.0.0.0' }
        @{ Version = '29.0.1'; Expected = '~> 29.0.1.0 >= 1.0.0.0' }
    ) {
        Get-BaseApplicationBuildConstraint -Version ([version]$Version) | Should -Be $Expected
    }

    Context 'meaning in Paket' -Skip:(-not $paketAvailable) {
        It 'accepts <Candidate> for 29.0.54011.55407: <Expected>' -ForEach @(
            @{ Candidate = '29.0.54010.1'; Expected = $true }
            @{ Candidate = '29.0.54011.0'; Expected = $true }
            @{ Candidate = '29.0.54011.55407'; Expected = $true }
            @{ Candidate = '29.0.54011.55575'; Expected = $true }
            @{ Candidate = '29.0.54012.0'; Expected = $false }
            @{ Candidate = '29.1.0.0'; Expected = $false }
        ) {
            $constraint = Get-BaseApplicationBuildConstraint -Version ([version]'29.0.54011.55407')
            Test-PaketInRange $constraint $Candidate | Should -Be $Expected
        }
    }
}
