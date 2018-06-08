Param(
    [Parameter(ValueFromPipelineByPropertyName=$True)]
    $ContainerName=$env:ContainerName,
    [Parameter(ValueFromPipelineByPropertyName=$True)]
    $AppFile,
    $SkipVerification=$env:SKIPVERIFICATION
)
if ($SkipVerification -eq 'true') {
  Publish-NavContainerApp -containerName $ContainerName -appFile $AppFile -SkipVerification
} else {
  Publish-NavContainerApp -containerName $ContainerName -appFile $AppFile
}