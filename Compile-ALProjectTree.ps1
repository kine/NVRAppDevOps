function Compile-ALProjectTree 
{
    Param (
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $CertPath,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $CertPwd,
        $OrderedApps,
        $PackagesPath
    )
    if (-not $PackagesPath) {
        $PackagesPath = Get-Location
    }
    foreach ($App in $OrderedApps) {
        Write-Host "**** Compiling $($App.name) ****"
        $ALC = (Get-ChildItem "C:\ProgramData\NavContainerHelper\Extensions\$ContainerName\" -Filter alc.exe -Recurse).FullName
        Write-Host "Running $ALC for $($App.name)"
        $AppPath = Split-Path -Path $App.AppPath
        Push-Location
        Set-Location $AppPath
        $escparser = '--%'
        $AppFileName = "$($App.publisher)_$($App.name)_$($App.version).app"
        Write-Host "Generating $AppFileName..."
        
        & $ALC $escparser /project:.\ /packagecachepath:"$PackagesPath"  | Convert-ALCOutputToTFS

        if ($CertPath) {
            Write-Host "Signing the app..."
            SignTool sign /f $CertPath /p $CertPwd /t http://timestamp.verisign.com/scripts/timestamp.dll $AppFileName
        }
        Copy-Item -Path $AppFileName -Destination $PackagesPath
        Pop-Location
    }
}