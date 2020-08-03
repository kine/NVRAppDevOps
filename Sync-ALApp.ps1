function Sync-ALApp
{
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName=$env:ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $AppName=$env:RELEASE_DEFINITIONNAME
    )

    Sync-BcContainerApp -containerName $ContainerName -appName $AppName
}