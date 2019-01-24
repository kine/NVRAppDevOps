function Publish-ALAppTree
{
  Param(
      [Parameter(ValueFromPipelineByPropertyName=$True)]
      $ContainerName=$env:ContainerName,
      $SkipVerification=$env:SKIPVERIFICATION,
      $OrderedApps,
      $PackagesPath,
      [ValidateSet('Add','Clean','Development')]
      [Parameter(ValueFromPipelineByPropertyName=$True)]
      [string]$syncMode = 'Development',
      [ValidateSet('Global','Tenant')]
      [Parameter(ValueFromPipelineByPropertyName=$True)]
      [string]$scope = 'Tenant',
      [Parameter(ValueFromPipelineByPropertyName=$True)]
      $AppDownloadScript
  )
  if (-not $PackagesPath) {
    $PackagesPath = Get-Location
  }
  foreach($App in $OrderedApps) {
    Write-Host "Publishing, installing and syncing app $($App.name)..."
    if ($App.AppPath -like '*.app') {
      $AppFile = $App.AppPath
    } else {
      $AppFile = (Get-ChildItem -Path $PackagesPath -Filter "$($App.publisher)_$($App.name)_*.app" | Select-Object -First 1).FullName
    }
    if (-not $AppFile) {
      Write-Host "App $($App.name) from $($App.publisher) not found."
      if ($AppDownloadScript) {
        Write-Host "Trying to download..."
        Download-ALApp -name $App.name -publisher $App.publisher -version $App.version -targetPath $PackagesPath -AppDownloadScript $AppDownloadScript
      }
    }
    if ($SkipVerification -eq 'true') {
      Publish-NavContainerApp -containerName $ContainerName -appFile $AppFile -SkipVerification -sync -install -syncMode $syncMode -scope $scope
    } else {
      Publish-NavContainerApp -containerName $ContainerName -appFile $AppFile -sync -install -syncMode $syncMode -scope $scope
    }
  }
}