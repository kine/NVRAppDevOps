function Run-DevelClient
{
    param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName=$env:ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ClientPath
    )

    $params = @()
    $session = Get-NavContainerSession -containerName $containerName -silent
    $databaseName = Invoke-Command -Session $session `
                   -ScriptBlock {$config = Get-NAVServerConfiguration -ServerInstance NAV -AsXml;$config.Configuration.appSettings.SelectSingleNode('./add[@key=''DatabaseName'']').value}
    Remove-NavContainerSession -containerName $containerName
   
    $params += @("database=`"$databaseName`",servername=`"$ContainerName`",ID=`"$ContainerName`",generatesymbolreference=1")
    $ClientExe = Join-Path -Path $ClientPath 'finsql.exe'
    Write-Host "Running: $($ClientExe) $params"
    & "$ClientExe" $params
    
}