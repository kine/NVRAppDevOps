function Get-ArtifactPackages {
    param(
        [string]$artifactUrl,
        [string]$appSymbolsFolder
    )
    Write-Host "Using Symbols Folder: $appSymbolsFolder"
    if (!(Test-Path -Path $appSymbolsFolder -PathType Container)) {
        New-Item -Path $appSymbolsFolder -ItemType Directory | Out-Null
    }

    Write-Host 'Copying Microsoft apps from artifact folder'
    $ArtifactPaths = Download-Artifacts -artifactUrl $artifactUrl -includePlatform
    if ((-not (Test-Path (Join-Path $ArtifactPaths[0] 'Applications'))) -and (-not (Test-Path (Join-Path $ArtifactPaths[0] 'Applications.*')))) {
        $AppPath = $ArtifactPaths[1]
    }
    else {
        $AppPath = $ArtifactPaths[0]
    }
    
    # Check for ModernDev path - use "program files" if it exists, otherwise use "pfiles"
    $ModernDevPath = if (Test-Path (Join-Path $ArtifactPaths[1] "\ModernDev\program files\Microsoft Dynamics NAV\")) {
        "\ModernDev\program files\Microsoft Dynamics NAV\*\AL Development Environment\System.app"
    }
    else {
        "\ModernDev\pfiles\Microsoft Dynamics NAV\*\AL Development Environment\System.app"
    }
    
    (Join-Path $ArtifactPaths[1] $ModernDevPath),
    (Join-Path $AppPath "\Applications.*\Microsoft_Application_*.app"),
    (Join-Path $AppPath "\Applications\Application\Source\Microsoft_Application.app"),
    (Join-Path $AppPath "\Applications.*\Microsoft_Base Application_*.app"),
    (Join-Path $AppPath "\Applications\BaseApp\Source\Microsoft_Base Application.app"),
    (Join-Path $AppPath "\Applications.*\Microsoft_System Application_*.app"),
    (Join-Path $AppPath "\Applications.*\Microsoft_Business Foundation_*.app"),
    (Join-Path $AppPath "\Applications\Application\Source\Microsoft_Business Foundation*.app"),
    (Join-Path $AppPath "\Applications\Shopify\App\Microsoft_Shopify Connector.app"),
    (Join-Path $AppPath "\Applications\BusinessFoundation\Source\Microsoft_Business Foundation.app"),
    (Join-Path $AppPath "\Applications\System Application\source\Microsoft_System Application.app") | ForEach-Object {
        if ($_) {
            if (Test-Path $_) {
                if (-not (Test-Path (Join-Path $appSymbolsFolder (Split-Path $_ -Leaf)))) {
                    Write-Host "Copying $([System.IO.Path]::GetFileName($_)) "
                    Copy-Item -Path $_ -Destination $appSymbolsFolder -Force
                }
            }
        } 
    }
}
