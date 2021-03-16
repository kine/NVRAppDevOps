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

    if ($databaseServer)  {
        $smoServer = New-Object Microsoft.SqlServer.Management.Smo.Server $databaseServer
        $Smo = [reflection.assembly]::Load("Microsoft.SqlServer.Smo, Version=$($smoServer.VersionMajor).$($smoServer.VersionMinor).0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91")
        $SmoExtended = [reflection.assembly]::Load("Microsoft.SqlServer.SmoExtended, Version=$($smoServer.VersionMajor).$($smoServer.VersionMinor).0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91")
        $ConnectionInfo = [reflection.assembly]::Load("Microsoft.SqlServer.ConnectionInfo, Version=$($smoServer.VersionMajor).$($smoServer.VersionMinor).0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91")
        $SqlEnum = [reflection.assembly]::Load("Microsoft.SqlServer.SqlEnum, Version=$($smoServer.VersionMajor).$($smoServer.VersionMinor).0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91")
                
        $OnAssemblyResolve = [System.ResolveEventHandler] {
            param($sender, $e)
            if ($e.Name -like "Microsoft.SqlServer.Smo, Version=*, Culture=neutral, PublicKeyToken=89845dcd8080cc91") { return $Smo }
            if ($e.Name -like "Microsoft.SqlServer.SmoExtended, Version=*, Culture=neutral, PublicKeyToken=89845dcd8080cc91") { return $SmoExtended }
            if ($e.Name -like "Microsoft.SqlServer.ConnectionInfo, Version=*, Culture=neutral, PublicKeyToken=89845dcd8080cc91") { return $ConnectionInfo }
            if ($e.Name -like "Microsoft.SqlServer.SqlEnum, Version=*, Culture=neutral, PublicKeyToken=89845dcd8080cc91") { return $SqlEnum }
            foreach($a in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
                if ($a.FullName -eq $e.Name) { return $a }
            }
            return $null
        }
        [System.AppDomain]::CurrentDomain.add_AssemblyResolve($OnAssemblyResolve)
    }
}