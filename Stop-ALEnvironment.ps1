function Start-Environment
{
    Param (
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName
    )

    docker stop $ContainerName
}