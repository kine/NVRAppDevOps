<#
.SYNOPSIS
    Invokes the Paket tool for AL projects.

.DESCRIPTION
    The Invoke-PaketForAl function is used to execute the Paket tool for managing dependencies in AL projects. 
    It provides a convenient way to restore, update, and clean the dependencies specified in the paket.dependencies file, which is generated from the app.json.

.PARAMETER ProjectPath
    Specifies the path to the AL project directory where the app.json file exists.

.PARAMETER Command
    Specifies the Paket command to execute. Valid values are 'install', 'restore', 'update', and 'clean'.

.PARAMETER UsePackagesAsCache
    Specifies whether to use the packages folder as a cache for the dependencies. If this switch is specified, the al.packageCachePath setting is added to the .vscode/settings.json file.

.PARAMETER Sources
    Specifies the NuGet sources to use for the Paket tool. The sources are specified in the form of '{url} username:"{username}" password:"{password}" authmethod:{authmethod}'. 
    If this parameter is not specified, the sources are read from the existing paket.dependencies file.

.PARAMETER PaketExePath
    Specifies the path to the Paket executable. If this parameter is not specified, the function uses the default path to the Paket executable set in system environment 
    variable PaketExePath. If not set, the path to paket installed with chcocolatey is used.

.EXAMPLE
    Invoke-PaketForAl -Path "C:\Projects\MyALProject" -Command "install" -Sources 'https://myaccount.pkgs.visualstudio.com/_packaging/FeedName/nuget/v3/index.json username:"" password:"%PAT%" authmethod:basic'
    This example install the dependencies specified in the paket.dependencies file for the AL project located at "C:\Projects\MyALProject".

.EXAMPLE
    Invoke-PaketForAl -Path "C:\Projects\MyALProject" -Command "update"
    This example updates the dependencies specified in the paket.dependencies file for the AL project located at "C:\Projects\MyALProject".

.EXAMPLE
    Invoke-PaketForAl -Path "C:\Projects\MyALProject" -Command "restore"
    This example restore the dependencies specified in the paket.dependencies to versions specified in paket.lock file for the AL project located at "C:\Projects\MyALProject".

.NOTES
    This function requires the Paket tool to be installed on the system. You can set the path to the Paket through PaketExePath parameter or system variable.
    For more information about Paket, visit https://fsprojects.github.io/Paket/.
#>
function Invoke-PaketForAl {
    param(
        $Command = 'install',
        $ProjectPath = (get-location),
        [switch]$UsePackagesAsCache,
        #Sources in form of '{url} username:"{username}" password:"{password}" authmethod:{authmethod}'. See Paket documentation for more information
        [string[]] $Sources,
        [string] $PaketExePath = $env:PaketExePath
    )

    if (-not $PaketExePath) {
        #paket path not passed, use default chocolatey path
        $PaketPath = 'C:\ProgramData\chocolatey\lib\Paket\tools\'
    }

    $PaketExe = Join-Path $PaketPath "paket.exe"
    if (-not (Test-Path $PaketExe)) {
        #if not found on the path, use default search mechanism
        $PaketExe = 'paket.exe'
        $PaketPath = ''
    }

    Write-Verbose "Creating/Updating paket.dependencies file..."
    ConvertTo-PaketDependencies -ProjectPath $ProjectPath -NuGetSources $Sources
    Write-Verbose "Running $PaketExe $Command..."
    & $PaketExe $Command

    if ($UsePackagesAsCache) {
        $SettingsPath = Join-Path $ProjectPath ".vscode/settings.json"
        if (-not (Test-Path $SettingsPath)) {
            $Settings = @{
                "al.packageCachePath" = @("packages")
            }
        }
        else {
            $Settings = Get-Content $SettingsPath | ConvertFrom-Json
            if ( [bool]($Settings.PSobject.Properties.name -match "al.packageCachePath")) {
                if (-not ($Settings."al.packageCachePath" | where-object { $_ -eq "packages" })) {
                    if ($Settings."al.packageCachePath".Count -gt 0) {
                        $Settings."al.packageCachePath" += "packages"
                    }
                    else {
                        $Settings."al.packageCachePath" = @($Settings["al.packageCachePath"], "packages")
                    }
                }
            }
            else {
                $Settings | Add-Member -MemberType NoteProperty -Name "al.packageCachePath" -Value @("packages")
            }
        }
        $Settings | ConvertTo-Json | Out-File $SettingsPath
    }
}