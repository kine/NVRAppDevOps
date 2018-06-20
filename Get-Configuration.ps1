function Get-Configuration 
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
        $ClientPath
    )

    $Configuration = New-Object -TypeName PSObject
    $Configuration | Add-Member -MemberType NoteProperty -Name 'ContainerName' -Value $ContainerName
    $Configuration | Add-Member -MemberType NoteProperty -Name 'ImageName' -Value $ImageName
    $Configuration | Add-Member -MemberType NoteProperty -Name 'LicenseFile' -Value $LicenseFile
    $Configuration | Add-Member -MemberType NoteProperty -Name 'VsixPath' -Value $VsixPath
    $Configuration | Add-Member -MemberType NoteProperty -Name 'PlatformVersion' -Value $PlatformVersion
    $Configuration | Add-Member -MemberType NoteProperty -Name 'AppVersion' -Value $AppVersion
    $Configuration | Add-Member -MemberType NoteProperty -Name 'TestAppVersion' -Value $TestAppVersion
    $Configuration | Add-Member -MemberType NoteProperty -Name 'AppName' -Value $AppName
    $Configuration | Add-Member -MemberType NoteProperty -Name 'TestAppName' -Value $TestAppName
    $Configuration | Add-Member -MemberType NoteProperty -Name 'AppFile' -Value $AppFile
    $Configuration | Add-Member -MemberType NoteProperty -Name 'TestAppFile' -Value $TestAppFile
    $Configuration | Add-Member -MemberType NoteProperty -Name 'Publisher' -Value $Publisher
    $Configuration | Add-Member -MemberType NoteProperty -Name 'TestPublisher' -Value $TestPublisher
    $Configuration | Add-Member -MemberType NoteProperty -Name 'RepoPath' -Value $RepoPath
    $Configuration | Add-Member -MemberType NoteProperty -Name 'AppPath' -Value $AppPath
    $Configuration | Add-Member -MemberType NoteProperty -Name 'TestAppPath' -Value $TestAppPath
    $Configuration | Add-Member -MemberType NoteProperty -Name 'Build' -Value $Build
    $Configuration | Add-Member -MemberType NoteProperty -Name 'Password' -Value $Password
    $Configuration | Add-Member -MemberType NoteProperty -Name 'ClientPath' -Value $ClientPath
    

    Write-Output $Configuration
}