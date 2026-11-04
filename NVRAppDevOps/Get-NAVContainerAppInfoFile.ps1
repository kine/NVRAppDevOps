<# 
 .Synopsis
  Get Nav App Info from Nav container
 .Description
  Creates a session to the Nav container and runs the Nav CmdLet Get-NavAppInfo in the container
 .Parameter ContainerName
  Name of the container in which you want to enumerate apps (default navserver)
 .Parameter AppPath
  Path where to findt the app file for whcih we want the info
 .Example
  Get-NavContainerAppInfo -ContainerName test2
 .Example
  Get-NavContainerAppInfo -ContainerName test2 -AppPath c:\app\myapp.app
#>
function Get-NavContainerAppInfoFile {
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $AppPath
    )
    $containerPath = Get-BcContainerPath -containerName $ContainerName -path $AppPath -throw
    #$args = @{"Path" = $containerPath}

    Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock { Param($Path)
        $info = Get-NavAppInfo -Path $Path
        # Since BC 29 AppId is a System.Guid carrying an extra 'Value' NoteProperty. PowerShell 7
        # serializes such a value as {"value": ..., "Value": ...}, which Windows PowerShell 5.1
        # ConvertFrom-Json on the host rejects as duplicate keys. Pass AppId as a plain string,
        # keeping the existing .AppId.value contract; all other properties are unchanged.
        $dto = [ordered]@{}
        foreach ($property in $info.PSObject.Properties) { $dto[$property.Name] = $property.Value }
        $appId = $info.AppId
        if ($null -ne $appId.Value) { $appId = $appId.Value }   # BC <= 28 wrapper type / BC 29 NoteProperty
        $dto.AppId = @{ value = [string]$appId }
        [pscustomobject]$dto | ConvertTo-Json -Depth 2
    } -argumentList $containerPath | ConvertFrom-Json
}
