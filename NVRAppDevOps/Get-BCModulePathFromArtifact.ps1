<#
.SYNOPSIS
    Get BC powershell modules path from artifact folder
.DESCRIPTION
    Get BC powershell modules from artifact folder to be used without entering the container to use BC cmdlets
.EXAMPLE
    PS C:\> Get-BCModulePathFromArtifact -artifactPath (Download-Artifacts -artifactUrl https://bcartifacts.azureedge.net/onprem/17.1.18256.18792/w1 -includePlatform)[1]
    Will download given artifact and return path to powershell modules for management and apps management
.INPUTS
    artifactPath - path to platform artifact of given version
    databaseServer - if set then libraries to interact with the database server are loaded (e.g. for Export-NAVApplication etc.)
.OUTPUTS
    array of paths
#>
function Get-BCModulePathFromArtifact {
    param(
        $artifactPath,
        $databaseServer
    )
    # Try with "program files" first, then fallback to "PFiles64" if not found
    $serviceTierPaths = @("ServiceTier\program files", "ServiceTier\PFiles64")
    
    $ManagementModule = $null
    $AppManagementModule = $null
    
    foreach ($serviceTierPath in $serviceTierPaths) {
        if (-not $ManagementModule) {
            $ManagementModule = Get-Item -Path (Join-Path $artifactPath "$serviceTierPath\Microsoft Dynamics NAV\*\Service\Microsoft.Dynamics.Nav.Management.psm1") -ErrorAction SilentlyContinue
        }
        if (-not $AppManagementModule) {
            $AppManagementModule = Get-Item -Path (Join-Path $artifactPath "$serviceTierPath\Microsoft Dynamics NAV\*\Service\Microsoft.Dynamics.Nav.Apps.Management.psd1") -ErrorAction SilentlyContinue
        }
        if (-not $ManagementModule) {
            $ManagementModule = Get-Item -Path (Join-Path $artifactPath "$serviceTierPath\Microsoft Dynamics NAV\*\Service\*\Microsoft.Dynamics.Nav.Management.psm1") -ErrorAction SilentlyContinue
        }
        if (-not $ManagementModule) {
            $ManagementModule = Get-Item -Path (Join-Path $artifactPath "$serviceTierPath\Microsoft Dynamics NAV\*\Service\*\Microsoft.Dynamics.Nav.Management.dll") -ErrorAction SilentlyContinue
        }
        if (-not $AppManagementModule) {
            $AppManagementModule = Get-Item -Path (Join-Path $artifactPath "$serviceTierPath\Microsoft Dynamics NAV\*\Service\*\Microsoft.Dynamics.Nav.Apps.Management.psd1") -ErrorAction SilentlyContinue
        }
        
        # If we found the management module, we can break early
        if ($ManagementModule) {
            break
        }
    }
    if (!($ManagementModule)) {
        throw "Unable to locate management module in artifacts $artifactPath"
    }
    # module doesn't exists for BCv24 Powwershell 5 bridge
    # if (!($AppManagementModule)) {
    #     throw "Unable to locate apps management module in artifacts $artifactPath"
    # }
    
    Write-Verbose "Found PowerShell module $($ManagementModule.FullName)"
    if ($AppManagementModule) {
        Write-Verbose "Found PowerShell module $($AppManagementModule.FullName)"
        $Paths = @($ManagementModule.FullName, $AppManagementModule.FullName)
    }
    else {
        $Paths = @($ManagementModule.FullName)
    }

    if ($databaseServer) {
        import-module SqlServer
        $SqlModule = get-module SqlServer
        $Path = Split-Path $SqlModule.Path
        $Smo = [Reflection.Assembly]::LoadFile((Join-Path $Path 'Microsoft.SqlServer.Smo.dll'))
        $SmoExtended = [Reflection.Assembly]::LoadFile((Join-Path $Path 'Microsoft.SqlServer.SmoExtended.dll'))
        $ConnectionInfo = [Reflection.Assembly]::LoadFile((Join-Path $Path 'Microsoft.SqlServer.ConnectionInfo.dll'))
        $SqlEnum = [Reflection.Assembly]::LoadFile((Join-Path $Path 'Microsoft.SqlServer.SqlEnum.dll'))
                
        $OnAssemblyResolve = [System.ResolveEventHandler] {
            param($sender, $e)
            if ($e.Name -like "Microsoft.SqlServer.Smo, Version=*, Culture=neutral, PublicKeyToken=89845dcd8080cc91") { return $Smo }
            if ($e.Name -like "Microsoft.SqlServer.SmoExtended, Version=*, Culture=neutral, PublicKeyToken=89845dcd8080cc91") { return $SmoExtended }
            if ($e.Name -like "Microsoft.SqlServer.ConnectionInfo, Version=*, Culture=neutral, PublicKeyToken=89845dcd8080cc91") { return $ConnectionInfo }
            if ($e.Name -like "Microsoft.SqlServer.SqlEnum, Version=*, Culture=neutral, PublicKeyToken=89845dcd8080cc91") { return $SqlEnum }
            foreach ($a in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
                if ($a.FullName -eq $e.Name) { return $a }
            }
            return $null
        }
        [System.AppDomain]::CurrentDomain.add_AssemblyResolve($OnAssemblyResolve)
    }
    return $Paths
}