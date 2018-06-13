function Upgrade-AppData
{
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName=$env:ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $AppName=$env:RELEASE_DEFINITIONNAME,
        $SameVersionExists=$env:SameVersionExists
    )
    if ($SameVersionExists -eq 'true') {
    } else {
        Start-NavContainerAppDataUpgrade -containerName $ContainerName -appName $AppName
    }
}