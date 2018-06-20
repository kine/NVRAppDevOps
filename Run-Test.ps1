function Run-Test
{
    param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName=$env:ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ClientPath,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $TestCodeunitId
    )
    $ClientExe = Join-Path -Path $ClientPath 'Microsoft.Dynamics.Nav.Client.exe'

    $params = @()
    $params += @('-showNavigationPage:0')
    $params += @('-language:1033')
    $params += @('-consolemode')
    $params += @("dynamicsnav://///RunCodeunit?Codeunit=$TestCodeunitId")

    Write-InfoMessage "Running $ClientExe $params"

    & $ClientExe $params | Out-Null

}