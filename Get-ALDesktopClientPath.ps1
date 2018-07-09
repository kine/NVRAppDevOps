function Get-DesktopClientPath
{
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName=$env:ContainerName
    )

    if (Test-Path "C:\ProgramData\NavContainerHelper\Extensions\$ContainerName\Program Files\") {
        $ClientFile = (get-childitem -Path "C:\ProgramData\NavContainerHelper\Extensions\$ContainerName\Program Files\" -Include "Microsoft.Dynamics.Nav.Client.exe" -Recurse | Select-Object -First 1).FullName
    }
    if ($ClientFile) {
        $ClientPath = (Split-Path ($ClientFile))
    } else {
        $ClientPath = ''
    }
    return $ClientPath
}