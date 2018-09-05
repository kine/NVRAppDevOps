function New-ALNuSpec
{
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $AppFile,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $AppName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Publisher,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $AppVersion,
        $NuspecFileName,
        $id,
        $authors='',
        $owners='',
        $licenseUrl='',
        $projectUrl='',
        $iconUrl='',
        $releaseNotes='',
        $description='',
        $copyright='',
        $tags='',
        $AppDependencies
    )
    $nuspec =@()
    $xmltext = @"
<?xml version="1.0"?>
<package xmlns="http://schemas.microsoft.com/packaging/2013/05/nuspec.xsd">
    <metadata>
        <id>$id</id>
        <version>$AppVersion</version>
        <authors>$authors</authors>
        <owners>$owners</owners>
"@
    if ($licenseUrl) {
        $xmltext +="        <licenseUrl>$licenseUrl</licenseUrl>"
    }
    if ($projectUrl) {
        $xmltext +="    <projectUrl>$projectUrl</projectUrl>"
    }
    if ($iconUrl) {
        $Xmltext +="       <iconUrl>$iconUrl</iconUrl>"
    }
    $xmltext +=@"
        <releaseNotes>$releaseNotes</releaseNotes>
        <description>$description</description>
        <copyright>$copyright</copyright>
        <tags>$tags</tags>
        <dependencies></dependencies>
    </metadata>
    <files>
        <file src="$(Split-Path -Leaf $AppFile)" target="" />
    </files>
</package>
"@
    $nuspec =[System.Xml.XmlDocument]$xmltext
    foreach($Dep in $AppDependencies) {
        $depXml = $nuspec.CreateElement('dependency','http://schemas.microsoft.com/packaging/2013/05/nuspec.xsd')
        $attr = $nuspec.CreateAttribute("id")
        $attr.Value = $Dep.name
        $depXml.Attributes.Append($attr) | out-null
        $attr = $nuspec.CreateAttribute("version")
        $attr.Value = $Dep.version
        $depXml.Attributes.Append($attr) | out-null
        $nuspec.package.metadata.SelectSingleNode("./*[name()='dependencies']").AppendChild($depXml)
    }
    $nuspec.Save($NuspecFileName)
    #remove-module NVRAppDevOps
    #import-module C:\git\NVRAppDevOps
    #import-module 'C:\Program Files\Microsoft Dynamics 365 Business Central\130\Service\Microsoft.Dynamics.Nav.Apps.Management.dll'
    #$apps=Get-ALAppOrder -Path C:\git\SubAppTest\Apps\
    #New-ALNuSpec -AppFile $apps[3].AppPath -AppName $apps[3].name -Publisher $apps[3].publisher -AppVersion $apps[3].version -NuspecFileName C:\git\SubAppTest\Apps\TestApp1.nuspec -id TestApp1 -AppDependencies $apps[3].dependencies
}