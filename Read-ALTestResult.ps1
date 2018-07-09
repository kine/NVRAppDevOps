function Read-ALTestResult
{
    param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName=$env:ContainerName
    )
    $session = Get-NavContainerSession -containerName $ContainerName -silent
    $CompanyName = Invoke-Command -Session $session `
                   -ScriptBlock {(Get-NAVCompany -ServerInstance NAV | Select-object -First 1).CompanyName}
    Remove-NavContainerSession -containerName $ContainerName
    Write-Host "Company name = '$CompanyName'"
    
    $proxy = New-WebServiceProxy -Uri "http://$($ContainerName):7047/NAV/WS/$($CompanyName)/Page/CALTestResults" -UseDefaultCredential -Class WS -Namespace NVRAppDevOps
    $TestResults = $proxy.ReadMultiple(@(),'',100000)
    Write-Output $TestResults
}