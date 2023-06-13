function Install-ALNugetPackageByPaket {
    [CmdletBinding()]
    Param(
        $PackageName,
        $Version,
        $Dependencies,
        $ApiKey,
        $SourceUrl,
        $DependencyVersion = 'Highest',
        [switch]$ExactVersion, #do not use DependencyVersion for the main package
        $TargetPath,
        $Key,
        $BaseApplicationVersion, #version of the base app to use for limiting the dependencies
        $IdPrefix #Will be used before AppName and all Dependency names
    )
    $paketdependencies = @()
    $paketdependencies += "source $($SourceUrl) username: `"user`" password: `"$($Key)`" authtype: `"basic`""
    if (-not ($env:ChocolateyInstall -or (Test-Path C:\ProgramData\chocolatey))) {
        Write-Host "Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
    Write-Host "Installing Paket..."
    & C:\ProgramData\chocolatey\choco install Paket -y
    $TempFolder = Join-Path $env:TEMP 'ALNugetApps'
    if (Test-Path $TempFolder) {
        Remove-Item $TempFolder -Force -Recurse | Out-Null
    }

    switch ($DependencyVersion) {
        "HighestMinor" { $paketdependencies += "strategy: max"; $paketdependencies += "lowest_matching: false" }
        "Highest" { $paketdependencies += "strategy: max"; $paketdependencies += "lowest_matching: false" }
        "Lowest" { $paketdependencies += "strategy: min"; $paketdependencies += "lowest_matching: true" }
        "Ignore" { $paketdependencies += "references: strict" }
    }
    if ($BaseApplicationVersion) {
        if ($BaseApplicationVersion.Contains('<') -or $BaseApplicationVersion.Contains('>')) {
            Write-Host "Adding $($IdPrefix)$(Format-AppNameForNuget `"Microsoft_Application`") $($BaseApplicationVersion) storage: none, strategy: max, lowest_matching: false"
            $paketdependencies += "nuget $($IdPrefix)$(Format-AppNameForNuget `"Microsoft_Application`") $($BaseApplicationVersion) storage: none, strategy: max, lowest_matching: false"
        }
        else {
            #We want to take the highest version of the base app but same or lower than the limiting version
            $BaseVersion = [version]$BaseApplicationVersion
            if ($BaseVersion.Build -ne 0) {
                #We want specific build - release to specific environment. Do not take anything higher
                Write-Host "Adding $($IdPrefix)$(Format-AppNameForNuget `"Microsoft_Application`") <= $($BaseApplicationVersion) storage: none, strategy: max, lowest_matching: false"
                $paketdependencies += "nuget $($IdPrefix)$(Format-AppNameForNuget `"Microsoft_Application`") <= $($BaseApplicationVersion) storage: none, strategy: max, lowest_matching: false"
            }
            else {
                #Generic build, thus compailing for specific version. We can take even apps supporting higher minor, but not major
                $BaseApplicationVersion = "$($BaseVersion.Major+1).0"
                Write-Host "Adding $($IdPrefix)$(Format-AppNameForNuget `"Microsoft_Application`") < $($BaseApplicationVersion) storage: none, strategy: max, lowest_matching: false"
                $paketdependencies += "nuget $($IdPrefix)$(Format-AppNameForNuget `"Microsoft_Application`") < $($BaseApplicationVersion) storage: none, strategy: max, lowest_matching: false"
            }
        }
    }
    New-Item -Path $TempFolder -ItemType directory -Force | Out-Null

    if ($Dependencies) {
        foreach ($dep in $Dependencies) {
            $PackageName = $dep.packageName
            $Version = $dep.version
            Write-Host "Adding $PackageName $Version into paket.dependencies..."
            if ($Version) {
                $paketdependencies += "nuget $($IdPrefix)$(Format-AppNameForNuget $PackageName) >= $($Version)"
            }
            else {
                $paketdependencies += "nuget $($IdPrefix)$(Format-AppNameForNuget $PackageName)"
            }
  
        }
    }
    else {
        Write-Host "Installing package '$IdPrefix$(Format-AppNameForNuget $PackageName)' version $($Version) $DependencyVersion from '$SourceUrl' to $TargetPath..."
        if ($Version) {
            $paketdependencies += "nuget $($IdPrefix)$(Format-AppNameForNuget $PackageName) >= $($Version)"
        }
        else {
            $paketdependencies += "nuget $($IdPrefix)$(Format-AppNameForNuget $PackageName)"
        }
    }
    Push-Location
    set-location $TempFolder
    $paketdependencies | Out-File paket.dependencies -Encoding utf8
    Write-Host "running paket.exe install..."
    & C:\ProgramData\chocolatey\lib\Paket\payload\paket.exe install
    Write-Host "Moving app files from $TempFolder to $TargetPath..."
    if ($DependencyVersion -eq 'Ignore') {
        Get-ChildItem -Path $TempFolder -Filter "$($PackageName)_*.app" -Recurse | Copy-Item -Destination $TargetPath -Container -Force | Out-Null
    }
    else {
        Get-ChildItem -Path $TempFolder -Filter *.app -Recurse | Copy-Item -Destination $TargetPath -Container -Force | Out-Null
    }
    Pop-Location
    Write-Host "Removing folder $TempFolder..."
    Remove-Item $TempFolder -Force -Recurse | Out-Null
}