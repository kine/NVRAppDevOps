function Publish-ALApp
{
  Param(
      [Parameter(ValueFromPipelineByPropertyName=$True)]
      $ContainerName=$env:ContainerName,
      [Parameter(ValueFromPipelineByPropertyName=$True)]
      $AppFile,
      $SkipVerification=$env:SKIPVERIFICATION,
      [ValidateSet('Add','Clean','Development')]
      [Parameter(ValueFromPipelineByPropertyName=$True)]
      [string]$syncMode = 'Development',
      [ValidateSet('Global','Tenant')]
      [Parameter(ValueFromPipelineByPropertyName=$True)]
      [string]$scope = 'Tenant' 
  )

  if ($SkipVerification -eq 'true') {
    Publish-NavContainerApp -containerName $ContainerName -appFile $AppFile -SkipVerification -syncMode $syncMode -scope $scope
  } else {
    Publish-NavContainerApp -containerName $ContainerName -appFile $AppFile -syncMode $syncMode -scope $scope
  }
}