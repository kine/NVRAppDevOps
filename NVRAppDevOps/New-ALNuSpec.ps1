function New-ALNuSpec {
    Param(
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $AppFile,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [Parameter(ParameterSetName = 'OldNaming')]
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        $AppName,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [Parameter(ParameterSetName = 'OldNaming')]
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        $Publisher,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [Parameter(ParameterSetName = 'OldNaming')]
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        $AppVersion,
        [Parameter(ParameterSetName = 'OldNaming')]
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        $AppId,
        [Parameter(ParameterSetName = 'OldNaming')]
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        $NuspecFileName,
        [Parameter(ParameterSetName = 'OldNaming')]
        $id,
        [Parameter(ParameterSetName = 'OldNaming')]
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        $authors = '',
        [Parameter(ParameterSetName = 'OldNaming')]
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        $owners = '',
        [Parameter(ParameterSetName = 'OldNaming')]
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        $licenseUrl = '',
        [Parameter(ParameterSetName = 'OldNaming')]
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        $projectUrl = '',
        [Parameter(ParameterSetName = 'OldNaming')]
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        $iconUrl = '',
        [Parameter(ParameterSetName = 'OldNaming')]
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        $releaseNotes = '',
        [Parameter(ParameterSetName = 'OldNaming')]
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        $description = '',
        [Parameter(ParameterSetName = 'OldNaming')]
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        $copyright = '',
        [Parameter(ParameterSetName = 'OldNaming')]
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        $tags = '',
        [Parameter(ParameterSetName = 'OldNaming')]
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        $AppDependencies,
        [Parameter(ParameterSetName = 'OldNaming')]
        $IdPrefix, #Will be used before AppName and all Dependency names
        [Parameter(ParameterSetName = 'OldNaming')]
        $DependencyFormat = '$($Dep.publisher)_$($Dep.name)',
        [Parameter(ParameterSetName = 'OldNaming')]
        [bool]$IncludeBaseApp = $false,
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        [switch]$UnifiedNaming,
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        [String]$DependencyTag #will use unified naming for the dependencies and the package
    )
    $nuspec = @()
    if ($UnifiedNaming) {
        $PackageId = Format-AppNameForNuget -publisher $Publisher -appname $AppName -id $AppId -tag '' -version $AppVersion
    }
    else {
        $PackageId = "$IdPrefix$(Format-AppNameForNuget $id)"
    }

    $xmltext = @"
<?xml version="1.0"?>
<package xmlns="http://schemas.microsoft.com/packaging/2013/05/nuspec.xsd">
    <metadata>
        <id>$PackageId</id>
        <version>$AppVersion</version>
        <authors>$([Security.SecurityElement]::Escape($authors))</authors>
        <owners>$([Security.SecurityElement]::Escape($owners))</owners>
"@
    if ($licenseUrl) {
        $xmltext += "        <licenseUrl>$([Security.SecurityElement]::Escape($licenseUrl))</licenseUrl>"
    }
    if ($projectUrl) {
        $xmltext += "    <projectUrl>$([Security.SecurityElement]::Escape($projectUrl))</projectUrl>"
    }
    if ($iconUrl) {
        $Xmltext += "       <iconUrl>$([Security.SecurityElement]::Escape($iconUrl))</iconUrl>"
    }
    $xmltext += @"
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
    $nuspec = [System.Xml.XmlDocument]$xmltext
    foreach ($Dep in $AppDependencies) {
        if ( $UnifiedNaming -or (((-not $IncludeBaseApp) -and ($Dep.publisher -ne 'Microsoft')) `
                    -or ($IncludeBaseApp -and (($Dep.publisher -ne 'Microsoft') -or ($Dep.name -eq 'Application'))))) {
            $depXml = $nuspec.CreateElement('dependency', 'http://schemas.microsoft.com/packaging/2013/05/nuspec.xsd')
            $attr = $nuspec.CreateAttribute("id")
            if ($UnifiedNaming) {
                $attr.Value = Format-AppNameForNuget -publisher $Dep.publisher -appname $Dep.name -id $Dep.id -tag $DependencyTag -version $Dep.version
            }
            else {
                $attr.Value = "$IdPrefix$(Format-AppNameForNuget $ExecutionContext.InvokeCommand.ExpandString($DependencyFormat))"
            }
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