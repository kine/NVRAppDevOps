<#
.SYNOPSIS
    Add view to selected package on Artifact server of Azure DevOps
.DESCRIPTION
    Add selected view to the Azure DevOps Artifact package to set quality of the package
.Parameter accountName
    Name of the Azure DevOps organization to use
.Parameter feedName
    ID of the Atifact feed
.Parameter packageName
    Name of the package
.Parameter packageVersion
    Version of the package
.Parameter packageQuality
    Name of the view to add to the package
.Parameter PAT
    PAT to use when connecting to Azure DevOps
.EXAMPLE
    PS C:\> Add-ArtifactView -accountName mycompany -feedName 31ea740e-abcd-abcd-abcd-112244334455 -packageName mypackagename -packageVersion 1.0.1234 -packageQuality 'Dev' -PAT $mypat
    Will add view Dev to package mypackagename in given feed and account
.OUTPUTS
    return value of the API call (nothing if ok)
#>
function Add-ArtifactView
{
  param(
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$accountName,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$feedName,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$packageName,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$packageVersion,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$packageQuality,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$PAT,
    [Parameter(ValueFromPipelineByPropertyName=$True)]
    [string]$packageType='nuget'
  )
  
  $ErrorActionPreference = "Stop"
  
  $json = '{ "views": { "op":"add", "path":"/views/-", "value":"' + $packageQuality + '" } }'
  Write-Verbose -Message $json
  
  $Token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PAT)"))
  $HeaderPatch = @{"Authorization" = "Basic "+$Token; "content-type" = "application/json-patch+json"}
  $tfsCollectionUri = "https://pkgs.dev.azure.com/$accountName"

  $requestUri = $tfsCollectionUri + "/_apis/packaging/feeds/$feedName/$packageType/packages/$packageName/versions/$packageVersion" + "?api-version=5.0-preview.1"
  Write-Verbose -Message $requestUri
  $reponse = Invoke-RestMethod -Uri $requestUri -UseDefaultCredentials -ContentType "application/json" -Method Patch -Body $json -Headers $HeaderPatch
  Write-Verbose -Message "Response: '$reponse'"
  Write-Output $reponse
}
