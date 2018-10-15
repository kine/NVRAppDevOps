function Get-ALConfiguration 
{
    Param(
        $ContainerName,
        $ImageName,
        $LicenseFile,
        $VsixPath,
        $AppVersion,
        $PlatformVersion,
        $TestAppVersion,
        $AppName,
        $TestAppName,
        $AppFile,
        $TestAppFile,
        $Publisher,
        $TestPublisher,
        $RepoPath,
        $AppPath,
        $TestAppPath,
        $Build,
        $Password,
        $ClientPath,
        $AppDownloadScript,
        [hashtable]$PathMap,
        $Username=$env:USERNAME,
        $Auth='Windows',
        $RAM='4GB',
        [String]$DockerHost,
        [PSCredential]$DockerHostCred,
        [bool]$DockerHostSSL

    )

    function Get-ResultPath 
    {
        param(
            $Path,
            [hashtable]$PathMap
        )
        $ResultPath = (Get-Item -Path $Path).FullName
        foreach($Path in $PathMap.Keys) {
            $ResultPath = $ResultPath.Replace($Path,$PathMap[$Path])
        }
        return $ResultPath
    }

    $Configuration = New-Object -TypeName PSObject
    $Configuration | Add-Member -MemberType NoteProperty -Name 'ContainerName' -Value $ContainerName
    $Configuration | Add-Member -MemberType NoteProperty -Name 'ImageName' -Value $ImageName
    $Configuration | Add-Member -MemberType NoteProperty -Name 'LicenseFile' -Value $LicenseFile
    $Configuration | Add-Member -MemberType NoteProperty -Name 'VsixPath' -Value (Get-ResultPath -Path $VsixPath -PathMap $PathMap)
    $Configuration | Add-Member -MemberType NoteProperty -Name 'PlatformVersion' -Value $PlatformVersion
    $Configuration | Add-Member -MemberType NoteProperty -Name 'AppVersion' -Value $AppVersion
    $Configuration | Add-Member -MemberType NoteProperty -Name 'TestAppVersion' -Value $TestAppVersion
    $Configuration | Add-Member -MemberType NoteProperty -Name 'AppName' -Value $AppName
    $Configuration | Add-Member -MemberType NoteProperty -Name 'TestAppName' -Value $TestAppName
    $Configuration | Add-Member -MemberType NoteProperty -Name 'AppFile' -Value (Get-ResultPath -Path $AppFile -PathMap $PathMap)
    $Configuration | Add-Member -MemberType NoteProperty -Name 'TestAppFile' -Value (Get-ResultPath -Path $TestAppFile -PathMap $PathMap)
    $Configuration | Add-Member -MemberType NoteProperty -Name 'Publisher' -Value $Publisher
    $Configuration | Add-Member -MemberType NoteProperty -Name 'TestPublisher' -Value $TestPublisher
    $Configuration | Add-Member -MemberType NoteProperty -Name 'RepoPath' -Value (Get-ResultPath -Path $RepoPath -PathMap $PathMap)
    $Configuration | Add-Member -MemberType NoteProperty -Name 'AppPath' -Value (Get-ResultPath -Path $AppPath -PathMap $PathMap)
    $Configuration | Add-Member -MemberType NoteProperty -Name 'TestAppPath' -Value (Get-ResultPath -Path $TestAppPath -PathMap $PathMap)
    $Configuration | Add-Member -MemberType NoteProperty -Name 'Build' -Value $Build
    $Configuration | Add-Member -MemberType NoteProperty -Name 'Password' -Value $Password
    $Configuration | Add-Member -MemberType NoteProperty -Name 'Username' -Value $Username
    $Configuration | Add-Member -MemberType NoteProperty -Name 'Auth' -Value $Auth
    $Configuration | Add-Member -MemberType NoteProperty -Name 'ClientPath' -Value (Get-ResultPath -Path $ClientPath -PathMap $PathMap)
    $Configuration | Add-Member -MemberType NoteProperty -Name 'AppDownloadScript' -Value $AppDownloadScript
    $Configuration | Add-Member -MemberType NoteProperty -Name 'RAM' -Value $RAM
    $Configuration | Add-Member -MemberType NoteProperty -Name 'DockerHost' -Value $DockerHost
    $Configuration | Add-Member -MemberType NoteProperty -Name 'DockerHostCred' -Value $DockerHostCred
    $Configuration | Add-Member -MemberType NoteProperty -Name 'DockerHostSSL' -Value $DockerHostSSL
    

    Write-Output $Configuration
}