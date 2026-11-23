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
        [String]$BaseApplicationVersion, #version of the base app to use for limiting the dependencies
        $IdPrefix, #Will be used before AppName and all Dependency names
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [switch]$UnifiedNaming,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [String]$DependencyTag
    )
    $paketdependencies = @()
    $paketdependencies += "source $($SourceUrl) username: `"user`" password: `"$($Key)`" authtype: `"basic`""
    if ($env:PaketExePath) {
        $PaketPath = $env:PaketExePath
    }
    else {
        if (-not ($env:ChocolateyInstall -or (Test-Path C:\ProgramData\chocolatey))) {
            Write-Host "Installing Chocolatey..."
            Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
        Write-Host "Installing Paket..."
        & C:\ProgramData\chocolatey\choco install Paket -y
        $PaketPath = 'C:\ProgramData\chocolatey\lib\Paket\payload\'
    }
    $TempFolder = Join-Path $env:TEMP 'ALN'
    Write-Host "Using $TempFolder as temporary folder..."
    if (Test-Path $TempFolder) {
        Remove-Item $TempFolder -Force -Recurse | Out-Null
    }
    
    switch ($DependencyVersion) {
        "HighestMinor" { $paketdependencies += "strategy: max"; $paketdependencies += "lowest_matching: false"; $baseStrategy = 'strategy: max, lowest_matching: false' }
        "Highest" { $paketdependencies += "strategy: max"; $paketdependencies += "lowest_matching: false"; $baseStrategy = 'strategy: max, lowest_matching: false' }
        "Lowest" { $paketdependencies += "strategy: min"; $paketdependencies += "lowest_matching: true"; $baseStrategy = 'strategy: min, lowest_matching: true' }
        "Ignore" { $paketdependencies += "references: strict"; $baseStrategy = 'strategy: min, lowest_matching: true' }
    }
    if ($BaseApplicationVersion) {
        if ($UnifiedNaming) {
            $BaseAppPackageName = Format-AppNameForNuget -publisher "Microsoft" -appname "Application" -id "" -tag $DependencyTag -version ''
            $PlatformAppPackageName = Format-AppNameForNuget -publisher "Microsoft" -appname "Platform" -id "" -tag $DependencyTag -version ''
        }
        else {
            $BaseAppPackageName = "$($IdPrefix)$(Format-AppNameForNuget `"Microsoft_Application`")"
            $PlatformAppPackageName = ''
        }
        $Constraint = Get-BaseApplicationVersionConstraint -BaseApplicationVersion $BaseApplicationVersion
        Write-Host "Adding $BaseAppPackageName $Constraint storage: none, $baseStrategy"
        $paketdependencies += "nuget $($BaseAppPackageName) $Constraint storage: none, $baseStrategy"
        if ($PlatformAppPackageName) {
            $PlatformMajor = [int]($BaseApplicationVersion.Trim('<>=~ ') -split '\.')[0]
            Write-Host "Adding $($PlatformAppPackageName) ~> $PlatformMajor storage: none, $baseStrategy"
            $paketdependencies += "nuget $($PlatformAppPackageName) ~> $PlatformMajor storage: none, $baseStrategy"
        }
        Write-Host "`$env:ADDITIONAL_PAKET_LINES: $($env:ADDITIONAL_PAKET_LINES)"
        if ($env:ADDITIONAL_PAKET_LINES) {
            Write-Host "Adding $($env:ADDITIONAL_PAKET_LINES)"
            $paketdependencies += $env:ADDITIONAL_PAKET_LINES
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
        if ($UnifiedNaming) {
            $PackageNameFormatted = $PackageName
        }
        else {
            $PackageNameFormatted = "$($IdPrefix)$(Format-AppNameForNuget $PackageName)"
        }

        Write-Host "Installing package $PackageNameFormatted version $($Version) $DependencyVersion from '$SourceUrl' to $TargetPath..."
        if ($Version) {
            if ($ExactVersion) {
                $paketdependencies += "nuget $PackageNameFormatted = $($Version)"
            }
            else {
                $paketdependencies += "nuget $PackageNameFormatted >= $($Version)"
            }
        }
        else {
            $paketdependencies += "nuget $PackageNameFormatted"
        }
    }
    Push-Location
    set-location $TempFolder
    $paketdependencies | Out-File paket.dependencies -Encoding utf8
    Write-Verbose "+++++paket.dependencies+++++"
    foreach ($line in $paketdependencies) {
        Write-Verbose $line
    }
    Write-Verbose "-----paket.dependencies-----"
    $PaketCmd = Join-Path $PaketPath "paket.exe"
    Write-Host "running: $PaketCmd install"
    & $PaketCmd install
    Write-Host "Moving app files from $TempFolder to $TargetPath..."
    if ($DependencyVersion -eq 'Ignore') {
        Get-ChildItem -Path (Join-Path $TempFolder "Packages\$($PackageName)") -Filter "*.app" -Recurse | Copy-Item -Destination $TargetPath -Container -Force | Out-Null
    }
    else {
        Get-ChildItem -Path $TempFolder -Filter *.app -Recurse | Copy-Item -Destination $TargetPath -Container -Force | Out-Null
    }
    Pop-Location
    Write-Host "Removing folder $TempFolder..."
    Remove-Item $TempFolder -Force -Recurse | Out-Null
}
