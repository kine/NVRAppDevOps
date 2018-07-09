function Test-ALApp
{
    param (
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$True)]
        $ContainerName=$env:ContainerName,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$True)]
        $ClientPath,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$True)]
        $TestCodeunitId,
        [Parameter(Mandatory=$true)]
        $TrxFile,
        [switch]$ErrorOnFailedTest
    )

    Run-Test -ContainerName $ContainerName -ClientPath $ClientPath -TestCodeunitId $TestCodeunitId
    $result = (Read-TestResult -ContainerName $ContainerName | Convert-TestResultToNunitResult -TrxFile $TrxFile)
    if ($ErrorOnFailedTest -and ($result.TestRun.ResultSummary.Counters.failed -gt 0)) {
        Write-Error "There is $($result.TestRun.ResultSummary.Counters.failed) failing tests!"
    }
}