Param (
    [Parameter(ValueFromPipelineByPropertyName=$True)]
    $ContainerName=$env:ContainerName
)

Remove-NavContainer -containerName $ContainerName