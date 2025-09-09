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

.PARAMETER Policy
    Specifies the policy to use for resolving dependencies. Valid values are 'Min' and 'Max'. The default value is 'Min'.

.PARAMETER MaxApplicationVersion
    Specifies the maximum version of the application to use for resolving dependencies. Will add '~> {version}' to the dependency in paket.dependencies file for the Microsoft.Application.

.PARAMETER MaxPlatformVersion
    Specifies the maximum version of the platform to use for resolving dependencies. Will add '~> {version}' to the dependency in paket.dependencies file for the Microsoft.Platform.
    
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
        $ProjectPath = (get-location).Path,
        [switch]$UsePackagesAsCache,
        #Sources in form of '{url} username:"{username}" password:"{password}" authmethod:{authmethod}'. See Paket documentation for more information
        [string[]] $Sources,
        [string] $PaketExePath = $env:PaketExePath,
        [ValidateSet('Max', 'Min')]
        [string]$Policy = 'Min',        
        [version]$MaxApplicationVersion,
        [version]$MaxPlatformVersion,
        [switch]$Symbols
    )

    # Helper function to detect file encoding
    function Get-FileEncoding {
        param(
            [Parameter(Mandatory = $true)]
            [string]$FilePath
        )
        
        if (-not (Test-Path $FilePath)) {
            throw "File not found: $FilePath"
        }
        
        $FileBytes = [System.IO.File]::ReadAllBytes($FilePath)
        
        # Check for BOM to determine encoding
        if ($FileBytes.Length -ge 3 -and $FileBytes[0] -eq 0xEF -and $FileBytes[1] -eq 0xBB -and $FileBytes[2] -eq 0xBF) {
            return [System.Text.Encoding]::UTF8
        }
        elseif ($FileBytes.Length -ge 2 -and $FileBytes[0] -eq 0xFF -and $FileBytes[1] -eq 0xFE) {
            return [System.Text.Encoding]::Unicode
        }
        elseif ($FileBytes.Length -ge 2 -and $FileBytes[0] -eq 0xFE -and $FileBytes[1] -eq 0xFF) {
            return [System.Text.Encoding]::BigEndianUnicode
        }
        elseif ($FileBytes.Length -ge 4 -and $FileBytes[0] -eq 0xFF -and $FileBytes[1] -eq 0xFE -and $FileBytes[2] -eq 0x00 -and $FileBytes[3] -eq 0x00) {
            return [System.Text.Encoding]::UTF32
        }
        else {
            # Try to detect if it's UTF-8 without BOM
            try {
                $Content = [System.Text.Encoding]::UTF8.GetString($FileBytes)
                $ReEncodedBytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
                if (Compare-Object -ReferenceObject $FileBytes -DifferenceObject $ReEncodedBytes -SyncWindow 0) {
                    return [System.Text.Encoding]::Default
                }
                else {
                    return [System.Text.UTF8Encoding]::new($false) # UTF-8 without BOM
                }
            }
            catch {
                return [System.Text.Encoding]::Default
            }
        }
    }

    # Helper function to update AL package cache path setting
    function Update-ALPackageCachePathSetting {
        param(
            [Parameter(Mandatory = $true)]
            [PSCustomObject]$Settings
        )
        
        if ([bool]($Settings.PSobject.Properties.name -match "al.packageCachePath")) {
            if (-not ($Settings."al.packageCachePath" | Where-Object { $_ -eq "packages" })) {
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
        
        return $Settings
    }

    # Helper function to write JSON with encoding preservation
    function Write-JsonWithEncoding {
        param(
            [Parameter(Mandatory = $true)]
            [string]$FilePath,
            
            [Parameter(Mandatory = $true)]
            [string]$JsonContent,
            
            [System.Text.Encoding]$Encoding = $null
        )
        
        if ($Encoding) {
            [System.IO.File]::WriteAllText($FilePath, $JsonContent, $Encoding)
        }
        else {
            # For new files, use UTF-8 without BOM
            [System.IO.File]::WriteAllText($FilePath, $JsonContent, [System.Text.UTF8Encoding]::new($false))
        }
    }

    if (-not $PaketExePath) {
        #paket path not passed, use default chocolatey path
        $PaketExePath = 'C:\ProgramData\chocolatey\lib\Paket\tools\'
    }

    $PaketExe = Join-Path $PaketExePath "paket.exe"
    if (-not (Test-Path $PaketExe)) {
        #if not found on the path, use default search mechanism
        $PaketExe = 'paket.exe'
        $PaketExePath = ''
    }

    Write-Verbose "Creating/Updating paket.dependencies file..."
    ConvertTo-PaketDependencies -ProjectPath $ProjectPath -NuGetSources $Sources -Policy $Policy -MaxApplicationVersion $MaxApplicationVersion -MaxPlatformVersion $MaxPlatformVersion -Symbols:$Symbols
    Write-Verbose "Running $PaketExe $Command..."
    & $PaketExe $Command

    if ($UsePackagesAsCache) {
        $SettingsPath = Join-Path $ProjectPath ".vscode/settings.json"
        $OriginalEncoding = $null
        
        if (-not (Test-Path $SettingsPath)) {
            # Create new settings for new file
            $Settings = @{
                "al.packageCachePath" = @("packages")
            }
        }
        else {
            # Load existing settings and detect encoding
            $OriginalEncoding = Get-FileEncoding -FilePath $SettingsPath
            $Settings = Get-Content $SettingsPath -Encoding $OriginalEncoding | ConvertFrom-Json
            $Settings = Update-ALPackageCachePathSetting -Settings $Settings
        }
        
        # Write the updated settings back to file with preserved encoding
        $JsonContent = $Settings | ConvertTo-Json
        Write-JsonWithEncoding -FilePath $SettingsPath -JsonContent $JsonContent -Encoding $OriginalEncoding
    }
}