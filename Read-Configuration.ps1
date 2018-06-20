function Read-Configuration
{    
    Param(
        $Path,
        $Build,
        $Password
    )

    . (Join-Path $Path 'Scripts\Settings.ps1')
    $ClientFile = (get-childitem -Path "C:\ProgramData\NavContainerHelper\Extensions\$ContainerName\Program Files\" -Include "Microsoft.Dynamics.Nav.Client.exe" -Recurse | Select-Object -First 1).FullName
    
    if ($ClientFile) {
        $ClientPath = (Split-Path ($ClientFile))
    } else {
        $ClientPath = ''
    }
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