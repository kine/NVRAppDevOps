function Remove-ALEnvironment
{
    Param (
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName=$env:ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [String]$DockerHost,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [PSCredential]$DockerHostCred,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [bool]$DockerHostSSL
    )

    Remove-NavContainer -containerName $ContainerName
}