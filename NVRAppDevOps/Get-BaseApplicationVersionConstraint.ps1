<#
.SYNOPSIS
    Converts a base application version into a Paket version constraint for Microsoft.Application.

.DESCRIPTION
    - Explicit constraint (starts with an operator such as ~>, >=, <): returned unchanged.
    - Specific build (e.g. 29.0.54011.55407): limited to <= Major.Minor.Build (<= 29.0.54011). The revision
      (patch) number is ignored.
    - Short version (e.g. 29.0 or 29): original "<=" limit, unchanged.
    - Generic version (29.0.0): any version below the next major.
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
        # Specific environment build: limit to Major.Minor.Build, the revision number is ignored.
        return "<= $($BaseVersion.Major).$($BaseVersion.Minor).$($BaseVersion.Build)"
    }

    if ($BaseVersion.Build -lt 0) {
        # Short version (29 or 29.0): keep the original upper limit unchanged.
        return "<= $BaseApplicationVersion"
    }

    # Generic version (29.0.0): any minor is fine, but not the next major.
    return "< $($BaseVersion.Major + 1).0"
}
