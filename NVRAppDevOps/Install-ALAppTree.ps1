function Install-ALAppTree
{
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName=$env:ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $AppName=$env:RELEASE_DEFINITIONNAME,
        $OrderedApps,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $AppDownloadScript
    )

    for ($i=$OrderedApps.Count;$i -gt 0;$i--) {
        Install-BcContainerApp -containerName $ContainerName -appName $OrderedApps[$i-1].name
    }
}