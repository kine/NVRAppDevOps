<#
.SYNOPSIS
    Get Work Item
.DESCRIPTION
    Read the work item from Azure DevOps
.Parameter accountName
    Name of the Azure DevOps organization to use
.Parameter PAT
    PAT to use when connecting to Azure DevOps
.Parameter OAuthToken
    OAuthToken to use for athentication (e.g. System.AccessToken from build agent)
.Parameter WINo
    Number of the Work Item
.Parameter WIUrl
    URL of the Work Item
.OUTPUTS
    return work item data
#>
function Get-WI
{
  param(
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,ParameterSetName='WINo')]
    [string]$accountName,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,ParameterSetName='WINo')]
    [string]$projectName,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,ParameterSetName='WINo')]
    [string]$WINo,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,ParameterSetName='WIUrl')]
    [string]$WIUrl,
    [Parameter(ValueFromPipelineByPropertyName=$True)]
    [string]$PAT,
    [Parameter(ValueFromPipelineByPropertyName=$True)]
    [string]$OAuthToken=''
  )
  
  $ErrorActionPreference = "Stop"
  
  $Token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PAT)"))
  if (-not $OAuthToken) {
    Write-Verbose -Message 'PAT authorization used'
    $Header = @{"Authorization" = "Basic "+$Token; "content-type" = "application/json"}
  } else {
    Write-Verbose -Message 'OAuth authorization used'
    $Header = @{"Authorization" = "Bearer "+$OAuthToken; "content-type" = "application/json"}
  }

  if ($WIUrl) {
    if (-not $WIUrl.Contains("api-version")) {
      if ($WIUrl.Contains("?")) {
        $requestUri = "$($WIUrl)&api-version=5.1"
      } else {
        $requestUri = "$($WIUrl)?api-version=5.1"
      }
    }
  } else {
    $requestUri = "https://dev.azure.com/$accountName/$projectName/_apis/wit/workitems/$($WINo)?api-version=5.1"
  }
  Write-Verbose -Message $requestUri
  $response = Invoke-RestMethod -Uri $requestUri -Method Get -Headers $Header -Verbose
  Return $response
}
