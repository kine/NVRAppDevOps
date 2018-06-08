Param(
    [Parameter(ValueFromPipelineByPropertyName=$True)]
    $ContainerName=$env:ContainerName,
    [Parameter(ValueFromPipelineByPropertyName=$True)]
    $AppName=$env:RELEASE_DEFINITIONNAME
)

Install-NavContainerApp -containerName $ContainerName -appName $AppName
