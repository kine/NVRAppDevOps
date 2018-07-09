function Unpublish-ALApp
{
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName=$env:ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $AppName=$env:RELEASE_DEFINITIONNAME,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $AppFile
    )

    $dockerapp = Get-NavContainerAppInfo -containerName $ContainerName | where-object {$_.Name -eq $AppName}
    $app = $AppFile #Get-ChildItem $env:AGENT_RELEASEDIRECTORY -Recurse -Filter *.app | Select-Object -Last 1
    if ($app) {
        if ((-not $dockerapp) -or $app.FullName.Contains($dockerapp.Version)) {
            Write-Host "##vso[task.setvariable variable=SameVersionExists]true"
            Write-Host "Same version detected!!! ($($dockerapp.Version))"
        }
        if ($dockerapp) {
            Write-Host "Unpublishing version $($dockerapp.Version)"
            Unpublish-NavContainerApp -containerName $ContainerName -appName $AppName -uninstall
        } else {
            Write-Host "No installed version found $dockerapp"
        }
    }
}