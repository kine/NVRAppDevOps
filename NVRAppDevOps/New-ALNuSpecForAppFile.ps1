<#
.SYNOPSIS
    Create NuSpec fil for given app file
.DESCRIPTION
    Read app manifest from the app file and create the NuSpec based on the info inside (using Unified naming rules). You can use the parameters to set other info in the NuSpec file.

.EXAMPLE
    PS C:\>  New-ALNuSpecForAppFile -AppFile 'MyBcExtension.app' -NuspecFileName 'MyPackage.nuspec' -authors 'authors' -owners 'owners' -description 'description' -DependencyTag 'W1'
    
    Will read the manifst from the MyBcExtension.app and will create MyPackage.nuspec file with all necessary info including dependencies on Application and Platform.

.PARAMETER AppFile
    Path to the app file to read the manifest from
    
.PARAMETER NuspecFileName
    Path to the NuSpec file to create

.PARAMETER authors
    Authors of the package

.PARAMETER owners
    Owners of the package

.PARAMETER licenseUrl
    License URL of the package

.PARAMETER projectUrl
    Project URL of the package

.PARAMETER iconUrl
    Icon URL of the package

.PARAMETER releaseNotes 
    Release notes of the package

.PARAMETER description
    Description of the package

.PARAMETER tags
    Tags of the package

.PARAMETER DependencyTag
    Tag to use for the dependencies. This will be used for the Microsoft dependencies to specify localization used

#>
function New-ALNuSpecForAppFile {
    Param(
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $AppFile,
        $NuspecFileName,
        $authors = '',
        $owners = '',
        $licenseUrl = '',
        $projectUrl = '',
        $iconUrl = '',
        $releaseNotes = '',
        $description = '',
        $copyright = '',
        $tags = '',
        [String]$DependencyTag #will use unified naming for the dependencies and the package
    )
    $AppFile = Get-AppJsonFromAppFile -appFile $AppFile
    $AppDependencies = $AppFile.dependencies
    if ($AppFile.application) {
        $AppDependency = @{
            id        = ''
            name      = "Application"
            publisher = 'Microsoft'
            version   = $AppFile.application
        }
        $AppDependencies += $AppDependency
    }
    if ($AppFile.platform) {
        $AppDependency = @{
            id        = ''
            name      = "Platform"
            publisher = 'Microsoft'
            version   = $AppFile.platform
        }
        $AppDependencies += $AppDependency
    }
    New-ALNuSpec -UnifiedNaming -AppFile $AppFile -AppName $AppFile.name -Publisher $AppFile.publisher -AppVersion $AppFile.version -AppId $AppFile.id -copyright '' -NuspecFileName $NuspecFileName -authors $authors -owners $owners -licenseUrl $licenseUrl -projectUrl $projectUrl -iconUrl $iconUrl -releaseNotes $releaseNotes -description $description -tags $tags -DependencyTag $DependencyTag  -AppDependencies $AppDependencies
}