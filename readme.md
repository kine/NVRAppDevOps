# NVR App DevOps scripts

## Install and update

Add the source server as repository by:

    Register-PSRepository -Name "NVRTools" -SourceLocation "https://navertica.pkgs.visualstudio.com/_packaging/NVRTools/nuget/v2" -Credential (Get-Credential) -InstallationPolicy Trusted -Verbose

As credentials enter your login (login@domain) and as password use your PAT (see e.g. https://navertica.visualstudio.com/_usersSettings/tokens)

After that you can install the module through:

    install-module NVRAppDevOps -Repository NVRTools -Credential (Get-Credential)

Or update through

    update-module NVRAppDevOps -Credential (Get-Credential)

## Basic using

Import the module

    Import-Module NVRAppDevOps

To init environment:

    Read-ALConfiguration -Path <path> | Init-ALEnvironment
    
<path> is where Scripts\settings.ps1 exists (.\ if you are in the root of the repo, ..\ if you are in subfolder like MainApp)

Another commands you can use:

    Install-ALApp
    Publish-ALApp
    Remove-ALEnvironment
    Run-ALDesktopClient
    Run-ALDevelClient
    Start-ALEnvironment
    Stop-ALEnvironment
    Sync-ALApp
    Unpublish-ALApp