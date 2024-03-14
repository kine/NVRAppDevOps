function Install-ALNugetPackage {
    [CmdletBinding()]
    Param(
        $PackageName,
        $Version,
        $Source,
        $ApiKey,
        $SourceUrl,
        $DependencyVersion = 'Highest',
        [switch]$ExactVersion, #do not use DependencyVersion for the main package
        $TargetPath,
        $Key,
        $IdPrefix, #Will be used before AppName and all Dependency names
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [switch]$UnifiedNaming,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [String]$DependencyTag
    )
    #$sources = Get-PackageSource | Where-Object {$_.Name -eq $Source}
    #if (-not $sources) {
    #Write-Host "Adding nuget source..."
    #Write-Verbose "nuget.exe sources Add -Name `"$Source`" -Source `"$SourceUrl`""
    if ($SourceUrl) {
        $exists = nuget.exe sources list -Format short | Where-Object { $_ -like "*$($SourceUrl)" }
        if ($exists) {
            Write-Host "Source already exists"
        }
        else {
            nuget.exe sources Add -Name "$Source" -Source "$SourceUrl"
        }
        if ($Key) {
            Write-Host "Update source key"
            nuget.exe source update -Name "$Source" -Username 'user' -Password $Key -StorePasswordInClearText
        }
    }
    $TempFolder = Join-Path $env:TEMP 'ALN'
    Write-Host "Using $TempFolder as temporary folder..."
    if (Test-Path $TempFolder) {
        Remove-Item $TempFolder -Force -Recurse | Out-Null
    }

    if (-not $ExactVersion) {
        if ($Version -and ($DependencyVersion -eq 'HighestMinor')) {
            Write-Host "Listing available versions"
            $Versions = nuget.exe list -Source "$Source" -AllVersions -NonInteractive "$IdPrefix$(Format-AppNameForNuget $PackageName)" | Where-Object { $_ -like "$IdPrefix$(Format-AppNameForNuget $PackageName) *" }
            $VersionNos = $versions | foreach-object { $V = [version]$_.Split(' ')[1]; If ($V.Revision -eq -1) { $V = [version]"$($V.Major).$($V.Minor).$($V.Build).0" }; $V }
            $V = [version]$Version
            switch ($true) {
                ($V -like '*.0.0.0') { $M = "$($V.Major).*.*.*"; break }
                ($V -like '*.*.0.0') { $M = "$($V.Major).*.*.*"; break }
                ($V -like '*.*.*.0') { $M = "$($V.Major).$($V.Minor).*.*"; break }
                ($V -like '*.*.*.*') { $M = "$($V.Major).$($V.Minor).$($V.Build).*"; break }
            }
            $LatestVersion = $VersionNos | Sort-Object -Descending | Where-Object { $_ -like $M } | Select-Object -First 1
            Write-Host "Latest version for requested $Version is $LatestVersion"
            $Version = $LatestVersion
        }
        if ($Version -and ($DependencyVersion -eq 'Lowest')) {
            Write-Host "Listing available versions"
            $Versions = nuget.exe list -Source "$Source" -AllVersions -NonInteractive "$IdPrefix$(Format-AppNameForNuget $PackageName)" | Where-Object { $_ -like "$IdPrefix$(Format-AppNameForNuget $PackageName) *" }
            $VersionNos = $versions | foreach-object { $V = [version]$_.Split(' ')[1]; If ($V.Revision -eq -1) { $V = [version]"$($V.Major).$($V.Minor).$($V.Build).0" }; $V }
            $V = [version]$Version
            switch ($true) {
                ($V -like '*.0.0.0') { $M = "$($V.Major).*.*.*"; break }
                ($V -like '*.*.0.0') { $M = "$($V.Major).$($V.Minor).*.*"; break }
                ($V -like '*.*.*.0') { $M = "$($V.Major).$($V.Minor).$($V.Build).*"; break }
                ($V -like '*.*.*.*') { $M = "$($V.Major).$($V.Minor).$($V.Build).$($V.Revision)"; break }
            }
            $LatestVersion = $VersionNos | Sort-Object | Where-Object { $_ -like $M } | Select-Object -First 1
            Write-Host "Lowest version for requested $Version is $LatestVersion"
            $Version = $LatestVersion
        }
    }
    New-Item -Path $TempFolder -ItemType directory -Force | Out-Null
    if ($UnifiedNaming) {
        $PackageNameFormatted = "$PackageName"
    }
    else {
        $PackageNameFormatted = "$IdPrefix$(Format-AppNameForNuget $PackageName)"
    }
    Write-Host "Installing package $PackageNameFormatted version $($Version) $DependencyVersion from '$Source' to $TargetPath..."

    if ($Version) {
        if ($Source) {
            nuget.exe install -Source "$Source" -Version $Version -OutputDirectory $TempFolder -NoCache -DependencyVersion $DependencyVersion $PackageNameFormatted
        }
        else {
            nuget.exe install -Version $Version -OutputDirectory $TempFolder -NoCache -DependencyVersion $DependencyVersion $PackageNameFormatted
        }
    }
    else {
        if ($Source) {
            nuget.exe install -Source "$Source" -OutputDirectory $TempFolder -NoCache -DependencyVersion $DependencyVersion $PackageNameFormatted
        }
        else {
            nuget.exe install -OutputDirectory $TempFolder -NoCache -DependencyVersion $DependencyVersion $PackageNameFormatted
        }
    }
    Write-Host "Moving app files from $TempFolder to $TargetPath..."
    Get-ChildItem -Path $TempFolder -Filter *.app -Recurse | Copy-Item -Destination $TargetPath -Container -Force | Out-Null
    Write-Host "Removing folder $TempFolder..."
    Remove-Item $TempFolder -Force -Recurse | Out-Null
}