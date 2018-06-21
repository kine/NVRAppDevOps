function Test-App
{
    param (
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$True)]
        $ContainerName=$env:ContainerName,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$True)]
        $ClientPath,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$True)]
        $TestCodeunitId,
        [Parameter(Mandatory=$true)]
        $TrxFile
    )

    Run-Test -ContainerName $ContainerName -ClientPath $ClientPath -TestCodeunitId $TestCodeunitId
    Read-TestResult -ContainerName $ContainerName | Convert-TestResultToNunitResult -TrxFile $TrxFile   
}