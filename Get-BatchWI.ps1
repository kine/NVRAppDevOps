<#
.SYNOPSIS
    Get Work Items in batch
.DESCRIPTION
    Read the work item from Azure DevOps
.Parameter accountName
    Name of the Azure DevOps organization to use
.Parameter PAT
    PAT to use when connecting to Azure DevOps
.Parameter OAuthToken
    OAuthToken to use for athentication (e.g. System.AccessToken from build agent)
.Parameter WINos
    Numbers of the Work Items
.Parameter Expand
    Value for API parameter $expand (None, Relations, Fields, Links, All)
.OUTPUTS
    return work items data
#>
function Get-BatchWI
{
  param(
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,ParameterSetName='WINo')]
    [string]$accountName,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,ParameterSetName='WINo')]
    [string]$projectName,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,ParameterSetName='ADOUrl')]
    [string]$ADOUrl,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
    [int[]]$WINos,
    [Parameter(ValueFromPipelineByPropertyName=$True)]
    [string]$PAT,
    [Parameter(ValueFromPipelineByPropertyName=$True)]
    [string]$OAuthToken='',
    [Parameter(ValueFromPipelineByPropertyName=$True)]
    [ValidateSet('None', 'Relations', 'Fields', 'Links', 'All')]
    $Expand='None'
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

  if ($ADOUrl) {
    $requestUri = "$ADOUrl/_apis/wit/workitemsbatch?api-version=5.1"
  } else {
    $requestUri = "https://dev.azure.com/$accountName/$projectName/_apis/wit/workitemsbatch?api-version=5.1"
  }

  $body=@{'$expand'=$Expand;'ids'=$WINos}
  
  Write-Verbose -Message $requestUri
  Write-Verbose -Message ($body|ConvertTo-Json)
  $response = Invoke-RestMethod -Uri $requestUri -Method Post -Body ($body|ConvertTo-Json) -Headers $Header -Verbose
  Return $response
}
