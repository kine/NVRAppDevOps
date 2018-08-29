function Install-ALAppTree
{
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName=$env:ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $AppName=$env:RELEASE_DEFINITIONNAME,
        $OrderedApps,
        $PackagesPath

    )

    foreach ($App in $OrderedApps) {
        Install-NavContainerApp -containerName $ContainerName -appName $App.name
    }
}