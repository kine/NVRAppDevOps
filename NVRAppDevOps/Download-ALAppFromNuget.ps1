<#
.SYNOPSIS
    Download APP File from nuget repository
.DESCRIPTION
    Compose nuget package name as "publisher.name" where spaces in name are replaced by underscore and will download the package
    from regitered nuget sources.

.EXAMPLE
    PS C:\> Download-ALAppFromNuget -name "MyApp" -publisher "me" -version 1.0.0 -path "c:\mypath"
    Will download package "me.MyApp" of version 1.0.0 at least from nuget server and place it into c:\mypath folder

.Parameter name
    Name of the app to download

.Parameter publisher
    Name of the publisher of the app to download

.Parameter version
    Needed version of the app to download

.Parameter path
    Path to place the downloaded App file

#>
function Download-ALAppFromNuget {
    param(
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $name,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $publisher,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $version,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $id,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $dependencies,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $path = '.\',
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [String]$baseApplicationVersion = '',
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $Source = '',
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $SourceUrl = '',
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $Key = '',
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [switch]$LatestVersion,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [ValidateSet('Lowest', 'HighestPatch', 'HighestMinor', 'Highest', 'Ignore')]
        $DependencyVersion = 'Highest',
        [bool]$UsePaket = $false,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [switch]$UnifiedNaming,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [String]$DependencyTag

    )
    if ($dependencies) {
        if ($LatestVersion) {
            $version = ''
        }
        if ($UsePaket) {
            Install-ALNugetPackageByPaket -Dependencies $dependencies -TargetPath $path -IdPrefix "" -SourceUrl $SourceUrl -Key $Key -DependencyVersion $DependencyVersion -BaseApplicationVersion $baseApplicationVersion -UnifiedNaming:$UnifiedNaming -DependencyTag $DependencyTag
        }
        else {
            foreach ($dep in $dependencies) {

                Install-ALNugetPackage -PackageName $dep.packageName -Version $dep.version -TargetPath $path -IdPrefix "" -Source $Source -SourceUrl $SourceUrl -Key $Key -DependencyVersion $DependencyVersion
            }
        }

    }
    else {
        if ($UnifiedNaming) {
            $packageName = Format-AppNameForNuget -publisher $publisher -appname $name -id $id -tag $DependencyTag -version ''
        }
        else {
            $DependencyFormat = '$($dep.publisher)_$($dep.name)'
            $packageName = Format-AppNameForNuget -Name ($ExecutionContext.InvokeCommand.ExpandString($DependencyFormat))
        }
        if ($LatestVersion) {
            $version = ''
        }
        if ($UsePaket) {
            Install-ALNugetPackageByPaket -PackageName $packageName -Version $version -TargetPath $path -IdPrefix "" -SourceUrl $SourceUrl -Key $Key -DependencyVersion $DependencyVersion -BaseApplicationVersion $baseApplicationVersion -UnifiedNaming:$UnifiedNaming -DependencyTag $DependencyTag
        }
        else {
            Install-ALNugetPackage -PackageName $packageName -Version $version -TargetPath $path -IdPrefix "" -Source $Source -SourceUrl $SourceUrl -Key $Key -DependencyVersion $DependencyVersion
        }
    }
    Remove-Item -Path "$path\Microsoft_Application*.app" -Force
}