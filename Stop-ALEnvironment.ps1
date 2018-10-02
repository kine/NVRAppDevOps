function Stop-ALEnvironment
{
    Param (
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [String]$DockerHost,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [PSCredential]$DockerHostCred,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [bool]$DockerHostSSL

    )

    docker stop $ContainerName
}