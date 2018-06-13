function Read-Configuration
{    
    Param(
        $Path,
        $Build,
        $Password
    )

    . (Join-Path $Path 'Scripts\Settings.ps1')

    $Configuration = . (Join-Path $PSScriptRoot 'Get-Configuration.ps1') `
                            -ContainerName $ContainerName `
                            -ImageName $ImageName `
                            -LicenseFile $LicenseFile `
                            -VsixPath $VsixPath `
                            -AppVersion $AppJSON.application `
                            -TestAppVersion $TestAppJSON.application `
                            -AppName $AppJSON.name `
                            -TestAppName $AppJSON.name `
                            -AppFile $AppFile `
                            -TestAppFile $TestAppFile `
                            -Publisher $AppJSON.publisher `
                            -TestPublisher $TestAppJSON.publisher `
                            -RepoPath $RepoPath `
                            -AppPath $AppPath `
                            -TestAppPath $TestAppPath `
                            -Build $Build `
                            -Password $Password

    Write-Output $Configuration
}