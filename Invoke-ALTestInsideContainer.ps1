function Invoke-ALTestInsideContainer
{
    param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName=$env:ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ClientPath,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $TestCodeunitId,
        [string] $TestResultsFile

    )
    $testResultFileName = "C:\ProgramData\NavContainerHelper\Test Results.xml"
    Invoke-NavContainerCodeunit -containerName $ContainerName -Codeunitid $TestCodeunitId -Argument $testResultFileName -MethodName "RunTests"
    (Get-Content -Path $testResultFileName -Raw | Convert-CALTestOutputToAzureDevOps).Save($testResultsFile)
}