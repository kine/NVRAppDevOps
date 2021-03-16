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
    $testResultFileName = "C:\ProgramData\BcContainerHelper\Test Results.xml"
    Invoke-BcContainerCodeunit -containerName $ContainerName -Codeunitid $TestCodeunitId -Argument $testResultFileName -MethodName "RunTests"
    (Get-Content -Path $testResultFileName -Raw | Convert-CALTestOutputToAzureDevOps).Save($testResultsFile)
}