function Install-ALNugetPackage
{
    [CmdletBinding()]
    Param(
        $PackageName,
        $Version,
        $Source,
        $ApiKey,
        $SourceUrl,
        $DependencyVersion='Highest',
        $TargetPath
    )
    #$sources = Get-PackageSource | Where-Object {$_.Name -eq $Source}
    #if (-not $sources) {
        #Write-Host "Adding nuget source..."
        #Write-Verbose "nuget.exe sources Add -Name `"$Source`" -Source `"$SourceUrl`""
    if ($SourceUrl) {
        nuget.exe sources Add -Name "$Source" -Source "$SourceUrl"
    }
    $TempFolder = Join-Path $env:TEMP 'ALNugetApps'
    if (Test-Path $TempFolder) {
        Remove-Item $TempFolder -Force | Out-Null
    }
    New-Item -Path $TempFolder -ItemType directory -Force | Out-Null
    Write-Verbose "Installing package from source to $TempFolder..."
    nuget.exe install -Source "$Source" -Version $Version -OutputDirectory $TempFolder -NoCache "$PackageName"
    Get-ChildItem -Path $TempFolder -Filter *.app -Recurse | Copy-Item -Destination $TargetPath -Container -Force | Out-Null
    Remove-Item $TempFolder -Force -Recurse | Out-Null
}