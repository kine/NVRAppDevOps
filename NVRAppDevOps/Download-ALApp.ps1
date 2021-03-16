<#
.SYNOPSIS
    Download APP File from repository

.DESCRIPTION
    Will trigger script for downloading the needed app file, e.g. from Azure DevOps Artifact server or from some file server
    Value from AppDownloadScript parameter will be called with parameters name, publisher, version and path in input object.

    It is used to download missing dependency when compiling the AppTree or Installing the AppTree

.EXAMPLE
    PS C:\> Download-ALApp -name "MyApp" -publisher "me" -version 1.0.0 -targetPath "c:\mypath" -AppDownloadScript "Download-ALAppFromNuget"
    Will download nuget package me.MyApp of version 1.0.0 or newer from registered nuget sources.

.Parameter name
    Name of the app to download

.Parameter publisher
    Name of the publisher of the app to download

.Parameter version
    Needed version of the app to download

.Parameter targetPath
    Path to place the downloaded App file

.Parameter AppDownloadScript
    Script to use to download the app. This should take parameters from pipeline with name "name", "publisher", "version" and "targetPath" 
    or extract them from input object. Script could copy the app from somewhere, download it from some server etc.

#>
function Download-ALApp
{
    param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $name,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $publisher,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $version,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $targetPath = '.\',
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $AppDownloadScript
    )

    Write-Host "Downloading App $name from $publisher version $version into $targetPath"
    if ($AppDownloadScript) {
        Write-Host "executing $AppDownloadScript"

        $Configuration = New-Object -TypeName PSObject
        $Configuration | Add-Member -MemberType NoteProperty -Name 'name' -Value $name
        $Configuration | Add-Member -MemberType NoteProperty -Name 'publisher' -Value $publisher
        $Configuration | Add-Member -MemberType NoteProperty -Name 'version' -Value $version
        $Configuration | Add-Member -MemberType NoteProperty -Name 'path' -Value $targetPath

        #$Configuration | $AppDownloadScript
        #Invoke-Expression -Command $AppDownloadScript
        [ScriptBlock]$sb = [ScriptBlock]::Create("`$Args | $AppDownloadScript") 
        Write-Host "Config: $Configuration"
        Invoke-Command -ScriptBlock $sb -Args $Configuration
    }
}