Param(
    [Parameter(ValueFromPipelineByPropertyName=$True)]
    $ContainerName=$env:ContainerName,
    [Parameter(ValueFromPipelineByPropertyName=$True)]
    $AppName=$env:RELEASE_DEFINITIONNAME
)

Sync-NavContainerApp -containerName $ContainerName -appName $AppName
