<#
.SYNOPSIS
    Compile the App in the given folder
.DESCRIPTION
    Run alc.exe to create .app file from the AL project folder, based on the App.Json.
.Parameter ContainerName
    Name of the container to use for compiling the project
.Parameter AppPath
    Path to the Main App folder with App.json for the main App
.Parameter TestAppPath
    Path to the Test App folder with App.json for the test App
.Parameter TestApp
    If specified, will compile Test App and not Main App

.EXAMPLE
    PS C:\> Read-ALConfiguration -Path c:\myproject | Compile-ALProject 
    Will read config from given path and compile the main App
.EXAMPLE
    PS C:\> Read-ALConfiguration -Path c:\myproject | Compile-ALProject -TestApp '1'
    Will read config from given path and compile the Test App
.OUTPUTS
    .app files with main app and test app in their folders
#>
function Compile-ALProject 
{
    Param (
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $AppPath,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $TestAppPath,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $TestApp
    )

    $ALC = (Get-ChildItem "C:\ProgramData\BcContainerHelper\Extensions\$ContainerName\" -Filter alc.exe -Recurse).FullName
    if (-not $TestApp) {
        Write-Host "Running $ALC for MainApp"
        Push-Location
        Set-Location $AppPath
        & $ALC --% /project:.\ /packagecachepath:.\.alpackages | Convert-ALCOutputToTFS
        Pop-Location
    } else {
        if ($TestAppPath) {
            Write-Host "Running $ALC for TestApp"
            Push-Location
            Set-Location $TestAppPath
            & $ALC --% /project:.\ /packagecachepath:.\.alpackages | Convert-ALCOutputToTFS
            Pop-Location
        }
    }
}