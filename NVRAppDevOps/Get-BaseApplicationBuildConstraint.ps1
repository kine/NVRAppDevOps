<#
.SYNOPSIS
    Builds the Paket constraint for Microsoft.Application limited to a specific environment build.

.DESCRIPTION
    The revision (4th number) of the version is ignored. For 29.0.54011.55407 it returns
    '~> 29.0.54011.0 >= 1.0.0.0', which Paket reads as "anything below 29.0.54012", i.e. up to and
    including every 29.0.54011.* package. Pessimistic constraint with four segments:
    https://fsprojects.github.io/Paket/nuget-dependencies.html#Pessimistic-version-constraint
    Note that '~> 29.0.54011' (three segments) would mean "< 29.1", which is too wide.
#>
function Get-BaseApplicationBuildConstraint {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [version]$Version
    )

    return "~> $($Version.Major).$($Version.Minor).$($Version.Build).0 >= 1.0.0.0"
}
