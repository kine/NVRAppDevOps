<#
.SYNOPSIS
    Create folder on the host and share it with everyone
.DESCRIPTION
    Create folder on the host and share it with everyone
.EXAMPLE
    PS C:\> Set-ALDockerHostFolder -DockerHost host -DockerHostCred (Get-Credential) -DockerHostSSL $false -HostPath "C:\Source" -ShareName "Source"
    Will create folder c:\source on the host "host" and share it as share "Source"
.Parameter DockerHost
    Remote docker host
.Parameter DockerHostCred
    Credentials to connect to the docker host
.Parameter DockerHostSSL
    Set to $true if host is using SSL for connection
.Parameter HostPath
    Path on the host to use as root folder for the source code folders
.Parameter ShareName
    Name under which the folder will be shared
.Parameter ShareMapAs
    Driver letter under which the share will be mapped on the local computer
#>
function Set-ALDockerHostFolder
{
    param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [String]$DockerHost,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [PSCredential]$DockerHostCred,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [bool]$DockerHostSSL=$false,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [String]$HostPath,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [String]$ShareName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [String]$ShareMapAs

    )
    if ($DockerHost) {
        Write-Host "Running Set-ALDockerHostFolder on remote $DockerHost" -ForegroundColor Green
        Invoke-Command -ComputerName $DockerHost -UseSSL:$DockerHostSSL -Credential $DockerHostCred -ScriptBlock {
            param(
                $HostPath, $ShareName
            ) 
            if (-not (Get-Module NVRAppDevOps -ListAvailable)) {
                install-module NVRAppDevOps -Force
            }
            Import-Module "NVRAppDevOps" -Force -DisableNameChecking
            Set-ALDockerHostFolder `
                -HostPath $HostPath `
                -ShareName $ShareName
    
        } -ArgumentList $HostPath, $ShareName
        if ($ShareMapAs) {
            New-PSDrive -Name $ShareMapAs -PSProvider "FileSystem" -Root "\\$DockerHost\$ShareName" -Scope Global -Persist
            Write-Host -ForegroundColor Green "Set mapping for the DockerHost like '$($HostPath):$($ShareMapAs):\\'"
        }
    } else {
        if (-not (Test-Path -Path $HostPath)) {
            New-Item -Path $HostPath -ItemType Directory -Force | Out-Null
        }

        New-SMBShare -Name $ShareName -Path $HostPath -ContinuouslyAvailable $True -FullAccess "everyone" -CachingMode NONE
        Write-Host "Share \\$DockerHost\$ShareName created" -ForegroundColor Green
    }
}