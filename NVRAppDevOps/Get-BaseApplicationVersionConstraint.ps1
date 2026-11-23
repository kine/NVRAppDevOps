<#
.SYNOPSIS
    Converts a base application version into a Paket version constraint for Microsoft.Application.

.DESCRIPTION
    - Explicit constraint (starts with an operator such as ~>, >=, <): returned unchanged.
    - Specific build (e.g. 29.0.54011.55407): only the Major.Minor.Build part is significant. The revision
      (patch) number is ignored, so any 29.0.54011.* package matches.
    - Generic version (e.g. 29.0 or 29): any version below the next major.
#>
function Get-BaseApplicationVersionConstraint {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseApplicationVersion
    )

    if ($BaseApplicationVersion -match '[<>=~].+') {
        return $BaseApplicationVersion
    }

    if ($BaseApplicationVersion.Contains('.')) {
        $BaseVersion = [version]$BaseApplicationVersion
    }
    else {
        $BaseVersion = [version]"$($BaseApplicationVersion).0"
    }

    if ($BaseVersion.Build -gt 0) {
        # Specific environment build: stay within Major.Minor.Build, ignore the revision number.
        return ">= $($BaseVersion.Major).$($BaseVersion.Minor).$($BaseVersion.Build) < $($BaseVersion.Major).$($BaseVersion.Minor).$($BaseVersion.Build + 1)"
    }

    # Generic version (29, 29.0 or 29.0.0): any minor is fine, but not the next major.
    return "< $($BaseVersion.Major + 1).0"
}
