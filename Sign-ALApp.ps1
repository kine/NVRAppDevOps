<#
.SYNOPSIS
    Sign the app file with certificate
.DESCRIPTION
    Sign the app file with certificate using passed password
.EXAMPLE
    Sign-ALApp -AppFile c:\AL\Myapp.app -CertPath https://mysite/mycert.cer -CertPwd Pass@word1
    
    Sign the Myapp.app with certificate downloaded from the URL and using password Pass@word1

.Parameter AppFile
    Path to the .app file to sign
.Parameter CertPath
    Path/URL of the certificate
.Parameter CertPwd
    Password for the certificate
#>

function Sign-ALApp
{
    param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $AppFile,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $CertPath,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $CertPwd
    ) 

    if (Test-Path "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\SignTool.exe") {
        $SignTool = (get-item "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\SignTool.exe").FullName
    } else {
        throw "Couldn't find SignTool.exe, please install Windows SDK from https://go.microsoft.com/fwlink/p/?LinkID=2023014"
    }

    $SignTool sign /f $CertPath /p $CertPwd /t http://timestamp.verisign.com/scripts/timestamp.dll $AppFile
}