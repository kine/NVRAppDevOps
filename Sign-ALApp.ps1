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

    SignTool sign /f $CertPath /p $CertPwd /t http://timestamp.verisign.com/scripts/timestamp.dll $AppFile
}