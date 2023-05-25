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
        $path = '.\',
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
        $BaseApplicationVersion = '',
        [bool]$UsePaket = $false

    )
    $DependencyFormat = '$($publisher)_$($name)'
    $packageName = Format-AppNameForNuget -Name ($ExecutionContext.InvokeCommand.ExpandString($DependencyFormat))
    if ($LatestVersion) {
        $version = ''
    }
    if ($UsePaket) {
        Install-ALNugetPackageByPaket -PackageName $packageName -Version $version -TargetPath $path -IdPrefix "" -Source $Source -SourceUrl $SourceUrl -Key $Key -DependencyVersion $DependencyVersion -BaseApplicationVersion $BaseApplicationVersion
    }
    else {
        Install-ALNugetPackage -PackageName $packageName -Version $version -TargetPath $path -IdPrefix "" -Source $Source -SourceUrl $SourceUrl -Key $Key -DependencyVersion $DependencyVersion
    }
}