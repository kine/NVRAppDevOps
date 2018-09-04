function Install-ALAppTree
{
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName=$env:ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $AppName=$env:RELEASE_DEFINITIONNAME,
        $OrderedApps

    )

    for ($i=$OrderedApps.Count;$i -gt 0;$i--) {
        Install-NavContainerApp -containerName $ContainerName -appName $OrderedApps[$i-1].name
    }
}