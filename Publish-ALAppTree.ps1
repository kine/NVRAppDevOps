function Publish-ALAppTree
{
  Param(
      [Parameter(ValueFromPipelineByPropertyName=$True)]
      $ContainerName=$env:ContainerName,
      $SkipVerification=$env:SKIPVERIFICATION,
      $OrderedApps,
      $PackagesPath
  )
  if (-not $PackagesPath) {
    $PackagesPath = Get-Location
  }
  foreach($App in $OrderedApps) {
    Write-Host "Publishing, installing and syncing app $($App.name)..."
    $AppFile = (Get-ChildItem -Path $PackagesPath -Filter "$($App.publisher)_$($App.name)_*.app" | Select-Object -First 1).FullName
    if ($SkipVerification -eq 'true') {
      Publish-NavContainerApp -containerName $ContainerName -appFile $AppFile -SkipVerification -sync -install
    } else {
      Publish-NavContainerApp -containerName $ContainerName -appFile $AppFile -sync -install
    }
  }
}