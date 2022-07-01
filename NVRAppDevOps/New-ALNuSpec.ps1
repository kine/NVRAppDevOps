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
        $AppDependencies,
        $IdPrefix, #Will be used before AppName and all Dependency names
        $DependencyFormat='$($Dep.publisher)_$($Dep.name)'
    )
    $nuspec =@()
    $xmltext = @"
<?xml version="1.0"?>
<package xmlns="http://schemas.microsoft.com/packaging/2013/05/nuspec.xsd">
    <metadata>
        <id>$IdPrefix$(Format-AppNameForNuget $id)</id>
        <version>$AppVersion</version>
        <authors>$([Security.SecurityElement]::Escape($authors))</authors>
        <owners>$([Security.SecurityElement]::Escape($owners))</owners>
"@
    if ($licenseUrl) {
        $xmltext +="        <licenseUrl>$([Security.SecurityElement]::Escape($licenseUrl))</licenseUrl>"
    }
    if ($projectUrl) {
        $xmltext +="    <projectUrl>$([Security.SecurityElement]::Escape($projectUrl))</projectUrl>"
    }
    if ($iconUrl) {
        $Xmltext +="       <iconUrl>$([Security.SecurityElement]::Escape($iconUrl))</iconUrl>"
    }
    $xmltext +=@"
        <releaseNotes>$([Security.SecurityElement]::Escape($releaseNotes))</releaseNotes>
        <description>$([Security.SecurityElement]::Escape($description))</description>
        <copyright>$([Security.SecurityElement]::Escape($copyright))</copyright>
        <tags>$([Security.SecurityElement]::Escape($tags))</tags>
        <dependencies></dependencies>
    </metadata>
    <files>
        <file src="$([Security.SecurityElement]::Escape($(Split-Path -Leaf $AppFile)))" target="" />
    </files>
</package>
"@
    $nuspec =[System.Xml.XmlDocument]$xmltext
    foreach($Dep in $AppDependencies) {
        if ($Dep.publisher -ne 'Microsoft') {
            $depXml = $nuspec.CreateElement('dependency','http://schemas.microsoft.com/packaging/2013/05/nuspec.xsd')
            $attr = $nuspec.CreateAttribute("id")
            $attr.Value = "$IdPrefix$(Format-AppNameForNuget $ExecutionContext.InvokeCommand.ExpandString($DependencyFormat))"
            $depXml.Attributes.Append($attr) | out-null
            $attr = $nuspec.CreateAttribute("version")
            $attr.Value = $Dep.version
            if ($Dep.MinVersion) {
                $attr.Value = $Dep.MinVersion
            }
            $depXml.Attributes.Append($attr) | out-null
            $nuspec.package.metadata.SelectSingleNode("./*[name()='dependencies']").AppendChild($depXml)
        }
    }
    $nuspec.Save($NuspecFileName)
}