function Unpublish-ALAppTree
{
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName=$env:ContainerName,
        $OrderedApps
    )

    for ($i=$OrderedApps.Count;$i -gt 0;$i--) {
        Write-Host "Unpublishing app $($OrderedApps[$i-1].name)"
        $AppName = $OrderedApps[$i-1].name
        $dockerapp = Get-NavContainerAppInfo -containerName $ContainerName | where-object {$_.Name -eq $AppName}
        $app = $OrderedApps[$i-1].AppPath #Get-ChildItem $env:AGENT_RELEASEDIRECTORY -Recurse -Filter *.app | Select-Object -Last 1
        if ($app) {
            #if ((-not $dockerapp) -or $app.FullName.Contains($dockerapp.Version)) {
                #Write-Host "##vso[task.setvariable variable=SameVersionExists]true"
            #    Write-Host "Same version detected!!! ($($dockerapp.Version))"
            #}
            if ($dockerapp) {
                Write-Host "Unpublishing version $($dockerapp.Version)"
                Unpublish-NavContainerApp -containerName $ContainerName -appName $AppName -uninstall
            } else {
                Write-Host "No installed version found $dockerapp"
            }
        }
    }
}