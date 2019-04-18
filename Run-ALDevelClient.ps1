function Run-ALDevelClient
{
    param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName=$env:ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ClientPath
    )

    $params = @()
    $databaseName = Invoke-ScriptInNavContainer -containerName $ContainerName `
                   -ScriptBlock {$config = Get-NAVServerConfiguration -ServerInstance NAV -AsXml;$config.Configuration.appSettings.SelectSingleNode('./add[@key=''DatabaseName'']').value}
   
    $params += @("database=`"$databaseName`",servername=`"$ContainerName`",ID=`"$ContainerName`",generatesymbolreference=1")
    $ClientExe = Join-Path -Path $ClientPath 'finsql.exe'
    Write-Host "Running: $($ClientExe) $params"
    & "$ClientExe" $params
    
}