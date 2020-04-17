<#
.SYNOPSIS
    Get result of WIQ from Azure DevOps
.DESCRIPTION
    Execute WIQ and return the result
.Parameter accountName
    Name of the Azure DevOps organization to use
.Parameter PAT
    PAT to use when connecting to Azure DevOps
    .Parameter OAuthToken
    OAuthToken to use for athentication (e.g. System.AccessToken from build agent)
.Parameter WIQ
    WIQL query to run and return the result    
.OUTPUTS
    return result of the WIQ
#>
function Get-WIQResult
{
  param(
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$accountName,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$projectName,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$WIQ,
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

  $requestUri = "https://dev.azure.com/$accountName/$projectName/_apis/wit/wiql?api-version=5.1"
  $body= @"
  {
    "query": "$WIQ"
  }
"@
  Write-Verbose -Message $requestUri
  Write-Verbose -Message ($body)
  $response = Invoke-RestMethod -Uri $requestUri -Method Post -Body $body -Headers $Header -Verbose
  Return $response
}
