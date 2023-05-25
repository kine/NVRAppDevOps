function Install-ALNugetPackageByPaket {
    [CmdletBinding()]
    Param(
        $PackageName,
        $Version,
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
        $paketdependencies += "nuget $($IdPrefix)$(Format-AppNameForNuget `"Microsoft_Application`") ~> $($BaseApplicationVersion) storage: none"
    }
    New-Item -Path $TempFolder -ItemType directory -Force | Out-Null

    Write-Host "Installing package '$IdPrefix$(Format-AppNameForNuget $PackageName)' version $($Version) $DependencyVersion from '$SourceUrl' to $TargetPath..."
    if ($Version) {
        $paketdependencies += "nuget $($IdPrefix)$(Format-AppNameForNuget $PackageName) => $($Version)"
    }
    else {
        $paketdependencies += "nuget $($IdPrefix)$(Format-AppNameForNuget $PackageName)"
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