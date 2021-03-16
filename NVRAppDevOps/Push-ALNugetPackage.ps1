function Push-ALNugetPackage
{
    [CmdletBinding()]
    Param(
        $PackagePath,
        $Source,
        $ApiKey,
        $SourceUrl
    )
    #$sources = Get-PackageSource | Where-Object {$_.Name -eq $Source}
    #if (-not $sources) {
        #Write-Host "Adding nuget source..."
        #Write-Verbose "nuget.exe sources Add -Name `"$Source`" -Source `"$SourceUrl`""
    if ($SourceUrl) {
        nuget.exe sources Add -Name "$Source" -Source "$SourceUrl"
    }
    Write-Verbose "Pushing package to source..."
    nuget.exe push -Source "$Source" -ApiKey "$ApiKey" "$PackagePath"
}