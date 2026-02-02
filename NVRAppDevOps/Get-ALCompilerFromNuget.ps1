<#
.SYNOPSIS
    Download AL Compiler from NuGet package Microsoft.Dynamics.BusinessCentral.Development.Tools
.DESCRIPTION
    Downloads the newest version of the Microsoft.Dynamics.BusinessCentral.Development.Tools package
    from nuget.org with the same major version as specified in RuntimeVersion parameter.
    Extracts the compiler and returns the path to alc.exe.

.EXAMPLE
    PS C:\> Get-ALCompilerFromNuget -RuntimeVersion "25.0" -TargetPath "c:\compiler"
    Will download the newest version of Microsoft.Dynamics.BusinessCentral.Development.Tools with major version 25
    and extract it to c:\compiler

.EXAMPLE
    PS C:\> Get-ALCompilerFromNuget -RuntimeVersion "26.1.12345.0" -TargetPath "c:\compiler"
    Will download the newest version of Microsoft.Dynamics.BusinessCentral.Development.Tools with major version 26
    and extract it to c:\compiler

.Parameter RuntimeVersion
    The runtime version to match. The major version will be extracted and used to find
    the newest package with matching major version.

.Parameter TargetPath
    Target path where the compiler will be extracted.

.OUTPUTS
    String - Path to the folder containing alc.exe
#>
function Get-ALCompilerFromNuget {
    param(
        # Runtime version - major version will be used to find matching package
        [Parameter(Mandatory = $true)]
        [String] $RuntimeVersion,
        # Target path for extracted compiler
        [Parameter(Mandatory = $true)]
        [String] $TargetPath
    )

    function Expand-7zipArchive {
        Param (
            [Parameter(Mandatory = $true)]
            [string] $Path,
            [string] $DestinationPath
        )
    
        $7zipPath = "$env:ProgramFiles\7-Zip\7z.exe"
    
        $use7zip = $false
        if ($bcContainerHelperConfig.use7zipIfAvailable -and (Test-Path -Path $7zipPath -PathType Leaf)) {
            try {
                $use7zip = [decimal]::Parse([System.Diagnostics.FileVersionInfo]::GetVersionInfo($7zipPath).FileVersion, [System.Globalization.CultureInfo]::InvariantCulture) -ge 19
            }
            catch {
                $use7zip = $false
            }
        }
    
        if ($use7zip) {
            Write-Host "using 7zip"
            Set-Alias -Name 7z -Value $7zipPath
            $command = '7z x "{0}" -o"{1}" -aoa -r' -f $Path, $DestinationPath
            Invoke-Expression -Command $command | Out-Null
        }
        else {
            Write-Host "using Expand-Archive"
            Expand-Archive -Path $Path -DestinationPath "$DestinationPath" -Force
        }
    }

    $packageName = "Microsoft.Dynamics.BusinessCentral.Development.Tools"
    $nugetApiUrl = "https://api.nuget.org/v3/index.json"

    # Parse major version from RuntimeVersion
    try {
        $versionObj = [System.Version]::Parse($RuntimeVersion)
        $majorVersion = $versionObj.Major
    }
    catch {
        # If parsing fails, try to extract just the first number
        if ($RuntimeVersion -match '^(\d+)') {
            $majorVersion = [int]$matches[1]
        }
        else {
            throw "Cannot parse RuntimeVersion '$RuntimeVersion'. Please provide a valid version string."
        }
    }

    Write-Host "Looking for $packageName with major version $majorVersion on nuget.org"

    if (Test-Path $TargetPath) {
        Write-Host "Removing $TargetPath"
        Remove-Item $TargetPath -Recurse -Force
    }

    # Get NuGet API endpoints
    Write-Host "Fetching NuGet API endpoints..."
    $prev = $global:ProgressPreference; $global:ProgressPreference = "SilentlyContinue"
    try {
        $nugetIndex = Invoke-RestMethod -UseBasicParsing -Method GET -Uri $nugetApiUrl
    }
    finally {
        $global:ProgressPreference = $prev
    }

    $searchUrl = $nugetIndex.resources | Where-Object { $_.'@type' -eq 'SearchQueryService' } | Select-Object -ExpandProperty '@id' -First 1
    $packageBaseAddressUrl = $nugetIndex.resources | Where-Object { $_.'@type' -eq 'PackageBaseAddress/3.0.0' } | Select-Object -ExpandProperty '@id' -First 1

    if (-not $searchUrl -or -not $packageBaseAddressUrl) {
        throw "Could not find required NuGet API endpoints"
    }

    # Search for the package
    Write-Host "Searching for package $packageName..."
    $prev = $global:ProgressPreference; $global:ProgressPreference = "SilentlyContinue"
    try {
        $searchResult = Invoke-RestMethod -UseBasicParsing -Method GET -Uri "$searchUrl`?q=$packageName&prerelease=false&take=50"
    }
    finally {
        $global:ProgressPreference = $prev
    }

    $package = $searchResult.data | Where-Object { $_.id -eq $packageName } | Select-Object -First 1
    if (-not $package) {
        throw "Package $packageName not found on nuget.org"
    }

    # Get all versions of the package
    Write-Host "Fetching available versions..."
    $versionsUrl = "$($packageBaseAddressUrl.TrimEnd('/'))/$($packageName.ToLowerInvariant())/index.json"
    $prev = $global:ProgressPreference; $global:ProgressPreference = "SilentlyContinue"
    try {
        $versionsResponse = Invoke-RestMethod -UseBasicParsing -Method GET -Uri $versionsUrl
    }
    finally {
        $global:ProgressPreference = $prev
    }

    # Filter versions by major version and find the latest
    $matchingVersions = $versionsResponse.versions | Where-Object {
        try {
            $v = [System.Version]::Parse($_)
            $v.Major -eq $majorVersion
        }
        catch {
            $false
        }
    } | ForEach-Object {
        [PSCustomObject]@{
            VersionString = $_
            Version       = [System.Version]::Parse($_)
        }
    } | Sort-Object -Property Version -Descending

    if (-not $matchingVersions -or $matchingVersions.Count -eq 0) {
        throw "No versions of $packageName found with major version $majorVersion"
    }

    $latestVersion = $matchingVersions[0].VersionString
    Write-Host "Found latest version with major version $majorVersion`: $latestVersion"

    # Use standard NuGet cache folder
    $nugetCacheFolder = Join-Path $env:USERPROFILE ".nuget\packages"
    $packageCacheFolder = Join-Path $nugetCacheFolder "$($packageName.ToLowerInvariant())\$($latestVersion.ToLowerInvariant())"
    
    if (Test-Path $packageCacheFolder) {
        Write-Host "Using cached package from $packageCacheFolder"
    }
    else {
        # Download the package to cache
        $downloadUrl = "$($packageBaseAddressUrl.TrimEnd('/'))/$($packageName.ToLowerInvariant())/$($latestVersion.ToLowerInvariant())/$($packageName.ToLowerInvariant()).$($latestVersion.ToLowerInvariant()).nupkg"
        
        Write-Host "Downloading package from $downloadUrl..."
        New-Item -Path $packageCacheFolder -ItemType Directory -Force | Out-Null
        
        $nupkgPath = Join-Path $packageCacheFolder "$($packageName.ToLowerInvariant()).$($latestVersion.ToLowerInvariant()).nupkg"
        
        $prev = $global:ProgressPreference; $global:ProgressPreference = "SilentlyContinue"
        try {
            Invoke-WebRequest -UseBasicParsing -Uri $downloadUrl -OutFile $nupkgPath
        }
        finally {
            $global:ProgressPreference = $prev
        }
        
        # Extract the nupkg in cache folder
        Write-Host "Extracting NuGet package to cache..."
        Expand-7zipArchive -Path $nupkgPath -DestinationPath $packageCacheFolder
    }

    # Copy from cache to target path
    Write-Host "Copying package contents to $TargetPath..."
    New-Item -Path $TargetPath -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$packageCacheFolder\*" -Destination $TargetPath -Recurse -Force

    # Find alc.exe path (exclude win32 and lib subfolders)
    $ALCPossiblePaths = (Get-ChildItem -Path $TargetPath -Filter alc.exe -Recurse | Where-Object { $_.FullName -notlike '*win32*' -and $_.FullName -notlike '*\lib\*' }).FullName
    if ($ALCPossiblePaths) {
        $ALCPath = (Split-Path ($ALCPossiblePaths | Select-Object -First 1))
    }
    else {
        $ALCPossiblePaths = (Get-ChildItem -Path $TargetPath -Filter alc.exe -Recurse | Where-Object { $_.FullName -like '*win32*' -and $_.FullName -notlike '*\lib\*' }).FullName
        if ($ALCPossiblePaths) {
            $ALCPath = (Split-Path ($ALCPossiblePaths | Select-Object -First 1))
        }
        else {
            throw "Could not find alc.exe in the extracted package"
        }
    }

    Write-Host "ALC.exe path: $($ALCPath)"

    return $ALCPath
}
