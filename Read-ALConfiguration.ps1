function Read-ALConfiguration
{    
    Param(
        $Path,
        $Build,
        $Password
    )

    . (Join-Path $Path 'Scripts\Settings.ps1')
    $ClientPath = Get-DesktopClientPath -ContainerName $ContainerName
    $Configuration = Get-Configuration `
                            -ContainerName $ContainerName `
                            -ImageName $ImageName `
                            -LicenseFile $LicenseFile `
                            -VsixPath $VsixPath `
                            -PlatformVersion $AppJSON.platform `
                            -AppVersion $AppJSON.version `
                            -TestAppVersion $TestAppJSON.version `
                            -AppName $AppJSON.name `
                            -TestAppName $TestAppJSON.name `
                            -AppFile $AppFile `
                            -TestAppFile $TestAppFile `
                            -Publisher $AppJSON.publisher `
                            -TestPublisher $TestAppJSON.publisher `
                            -RepoPath $RepoPath `
                            -AppPath $AppPath `
                            -TestAppPath $TestAppPath `
                            -Build $Build `
                            -Password $Password `
                            -ClientPath $ClientPath

    Write-Output $Configuration
}