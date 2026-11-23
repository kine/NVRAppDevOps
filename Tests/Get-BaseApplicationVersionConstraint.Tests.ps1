BeforeAll {
    . (Join-Path $PSScriptRoot '..\NVRAppDevOps\Get-BaseApplicationVersionConstraint.ps1')
}

Describe 'Get-BaseApplicationVersionConstraint' {
    It 'ignores the revision (patch) number for a specific environment build' {
        Get-BaseApplicationVersionConstraint -BaseApplicationVersion '29.0.54011.55407' |
            Should -Be '>= 29.0.54011 < 29.0.54012'
    }

    It 'never limits to an exact full version with <=' {
        Get-BaseApplicationVersionConstraint -BaseApplicationVersion '29.0.54011.55407' |
            Should -Not -Match '<='
    }

    It 'accepts a three-part build version' {
        Get-BaseApplicationVersionConstraint -BaseApplicationVersion '29.0.54011' |
            Should -Be '>= 29.0.54011 < 29.0.54012'
    }

    It 'treats the smallest non-zero build as a specific build' {
        Get-BaseApplicationVersionConstraint -BaseApplicationVersion '29.0.1.5' |
            Should -Be '>= 29.0.1 < 29.0.2'
    }

    It 'keeps a non-zero minor in the specific build range' {
        Get-BaseApplicationVersionConstraint -BaseApplicationVersion '29.1.54011.7' |
            Should -Be '>= 29.1.54011 < 29.1.54012'
    }

    It 'allows any minor of the same major for a generic version <Version>' -ForEach @(
        @{ Version = '29.0' }
        @{ Version = '29' }
        @{ Version = '29.0.0' }
        @{ Version = '29.0.0.5' }
    ) {
        Get-BaseApplicationVersionConstraint -BaseApplicationVersion $Version |
            Should -Be '< 30.0'
    }

    It 'passes an explicit constraint through unchanged: <Constraint>' -ForEach @(
        @{ Constraint = '~> 29.0' }
        @{ Constraint = '>= 29.0.54011.55407' }
    ) {
        Get-BaseApplicationVersionConstraint -BaseApplicationVersion $Constraint |
            Should -Be $Constraint
    }
}
