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
        Get-NavAppInfo -Path $Path | ConvertTo-Json -Depth 2
    } -argumentList $containerPath | ConvertFrom-Json
}
