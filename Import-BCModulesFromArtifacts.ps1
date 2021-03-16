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
#>
function Import-BCModulesFromArtifacts
{
    param(
        $artifactPath
    )
    $ManagementModule = Get-Item -Path (Join-Path $artifactPath "ServiceTier\program files\Microsoft Dynamics NAV\*\Service\Microsoft.Dynamics.Nav.Management.psm1")
    $AppManagementModule = Get-Item -Path (Join-Path $artifactPath "ServiceTier\program files\Microsoft Dynamics NAV\*\Service\Microsoft.Dynamics.Nav.Apps.Management.psd1")
    if (!($ManagementModule)) {
        throw "Unable to locate management module in artifacts"
    }
    if (!($AppManagementModule)) {
        throw "Unable to locate apps management module in artifacts"
    }
    
    Write-Host "Importing PowerShell module $($ManagementModule.FullName)"
    Import-Module $ManagementModule.FullName -Global
    Write-Host "Importing PowerShell module $($AppManagementModule.FullName)"
    Import-Module $AppManagementModule.FullName -Global
}