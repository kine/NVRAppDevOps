function Read-ALConfiguration {
    Param(
        #Path to the repository
        $Path = '.\',
        #If set, scripts will work as under VSTS/TFS. If not set, it will work in "interactive" mode
        $Build,
        #Password which will be used for the container user - when WindowsAuthentication used, it is the domain password of the current user
        $Password,
        $Username = $env:USERNAME,
        [ValidateSet('Windows', 'NavUserPassword')]
        $Auth = 'Windows',
        $Profile = 'default',
        $SettingsFileName = '',
        $ExcludePath = '*\Dependencies\*'

    )
    $SettingsScript = (Join-Path $Path 'Scripts\Settings.ps1')
    if (Test-Path $SettingsScript) {
        Write-Host "Running $SettingsScript ..."
        . (Join-Path $Path 'Scripts\Settings.ps1')
    }

    $AuthParam = $Auth
    Remove-Variable -Name Auth

    $UsernameParam = $Username
    Remove-Variable -Name Username

    $PasswordParam = $Password
    Remove-Variable -Name Password

    Read-ALJsonConfiguration -Path $Path -SettingsFileName $SettingsFileName -Profile $Profile -ExcludePath $ExcludePath

    if ($Auth -eq $null) {
        $Auth = $AuthParam
    }
    if ($Username -eq $null) {
        $Username = $UsernameParam
    }
    if ($Password -eq $null) {
        $Password = $PasswordParam
    }
    if ($IncludeCSide -eq $null) {
        $IncludeCSide = $true
    }
    if ($EnableSymbolLoading -eq $null) {
        $EnableSymbolLoading = $true
    }
    if ($CreateTestWebServices -eq $null) {
        $CreateTestWebServices = $true
    }
    if ($Isolation -eq $null) {
        $Isolation = ''
    }
    if ($TestLibraryOnly -eq $null) {
        $TestLibraryOnly = $false
    }
    $ClientPath = Get-ALDesktopClientPath -ContainerName $ContainerName
    $Configuration = Get-ALConfiguration `
        -ContainerName $ContainerName `
        -ImageName $ImageName `
        -LicenseFile $LicenseFile `
        -VsixPath $VsixPath `
        -Isolation $Isolation `
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
        -Build $Build  `
        -Password $Password `
        -ClientPath $ClientPath `
        -AppDownloadScript $AppDownloadScript `
        -PathMap $PathMap `
        -Auth $Auth `
        -Username $Username `
        -RAM $RAM `
        -optionalParameters $optionalParameters `
        -EnableSymbolLoading $EnableSymbolLoading `
        -CreateTestWebServices $CreateTestWebServices `
        -IncludeCSide $IncludeCSide `
        -TestLibraryOnly $TestLibraryOnly `
        -CustomScripts $CustomScripts `
        -ArtifactUrl $ArtifactUrl

    Write-Output $Configuration
}
