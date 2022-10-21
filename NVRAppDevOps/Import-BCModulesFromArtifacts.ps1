<#
.SYNOPSIS
    Import BC powershell modules from artifact folder
.DESCRIPTION
    Import BC powershell modules from artifact folder to be used without entering the container to use BC cmdlets
.EXAMPLE
    PS C:\> Import-BCModulesFromArtifacts -artifactPath (Download-Artifacts -artifactUrl https://bcartifacts.azureedge.net/onprem/17.1.18256.18792/w1 -includePlatform)[1]
    Will download given artifact and load the powershell modules for management and apps management
.INPUTS
    artifactPath - path to platform artifact of given version
    databaseServer - if set then libraries to interact with the database server are loaded (e.g. for Export-NAVApplication etc.)
#>
function Import-BCModulesFromArtifacts
{
    param(
        $artifactPath,
        $databaseServer
    )
    $Paths = Get-BCModulePathFromArtifact -artifactPath $artifactPath

    try { [System.IO.File]::WriteAllText((Join-Path $artifactPath 'lastused'), "$([datetime]::UtcNow.Ticks)") } catch {}
    
    Import-Module $Paths -Global

}