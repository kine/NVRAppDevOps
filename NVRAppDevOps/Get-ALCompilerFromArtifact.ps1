function Get-ALCompilerFromArtifact {
    param(
        # URL of the artifact to be used
        [Parameter(Mandatory = $true)]
        [String] $ArtifactUrl,
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

    if (Test-Path $TargetPath) {
        Write-Host "Removing $TargetPath"
        Remove-Item $TargetPath -Recurse -Force
    }
    $Path = (Download-Artifacts -artifactUrl $ArtifactUrl -includePlatform)[1]
    if (Test-Path (Join-Path $Path 'ModernDev\Program Files\Microsoft Dynamics NAV\')) {
        $SubPath = 'ModernDev\Program Files\Microsoft Dynamics NAV\'
    }
    else {
        $SubPath = 'ModernDev\pfiles\microsoft dynamics nav\'
    }
    $Path = Join-Path $Path $SubPath
    Write-Host "Locating the vsix path in $Path"
    $VSIXPath = Get-ChildItem -Path $Path -Recurse -Filter ALLanguage.vsix
    #C:\bcartifacts.cache\sandbox\27.0.38460.39168\platform\ModernDev\pfiles\microsoft dynamics nav\270\al development environment
    Write-Host "Extracting ALLanguage.vsix into $TargetPath"
    Expand-7zipArchive -Path $VSIXPath.FullName -DestinationPath $TargetPath
    $ALCPossiblePaths = (Get-ChildItem -Path $TargetPath -Filter alc.exe -Recurse | Where-Object { $_.FullName -notlike '*win32*' }).FullName
    if ($ALCPossiblePaths) {
        $ALCPath = (Split-Path ($ALCPossiblePaths))
    }
    else {
        $ALCPath = (Split-Path (Get-ChildItem -Path $TargetPath -Filter alc.exe -Recurse | Where-Object { $_.FullName -like '*win32*' }).FullName)
    }
    Write-Host "ALC.exe path: $($ALCPath)"
    return $ALCPath
}