BeforeAll {
    . (Join-Path $PSScriptRoot '..\NVRAppDevOps\Get-BaseApplicationVersionConstraint.ps1')
}

Describe 'Get-BaseApplicationVersionConstraint' {
    It 'limits a specific build to Major.Minor.Build and drops the revision: <Version>' -ForEach @(
        @{ Version = '29.0.54011.55407'; Expected = '<= 29.0.54011' }
        @{ Version = '29.0.54011'; Expected = '<= 29.0.54011' }
        @{ Version = '29.1.2.3'; Expected = '<= 29.1.2' }
        @{ Version = '29.1.2.0'; Expected = '<= 29.1.2' }
        @{ Version = '29.0.1'; Expected = '<= 29.0.1' }
        @{ Version = '29.0.1.5'; Expected = '<= 29.0.1' }
        @{ Version = '29.1.54011.7'; Expected = '<= 29.1.54011' }
    ) {
        Get-BaseApplicationVersionConstraint -BaseApplicationVersion $Version |
            Should -Be $Expected
    }

    It 'allows any minor of the same major for a generic version <Version>' -ForEach @(
        @{ Version = '29.0.0' }
        @{ Version = '29.0.0.5' }
        @{ Version = '29.1.0.0' }
    ) {
        Get-BaseApplicationVersionConstraint -BaseApplicationVersion $Version |
            Should -Be '< 30.0'
    }

    It 'keeps the original "<=" limit for a short version <Version>' -ForEach @(
        @{ Version = '29.0' }
        @{ Version = '29.1' }
        @{ Version = '29' }
    ) {
        Get-BaseApplicationVersionConstraint -BaseApplicationVersion $Version |
            Should -Be "<= $Version"
    }

    It 'passes an explicit constraint through unchanged: <Constraint>' -ForEach @(
        @{ Constraint = '~> 29.0' }
        @{ Constraint = '>= 29.0.54011.55407' }
    ) {
        Get-BaseApplicationVersionConstraint -BaseApplicationVersion $Constraint |
            Should -Be $Constraint
    }
}
