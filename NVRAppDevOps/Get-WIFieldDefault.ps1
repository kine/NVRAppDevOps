<#
.SYNOPSIS
    Get Work Item Field default
.DESCRIPTION
    Get the settins for Work Item Field and return the default value
.Parameter accountName
    Name of the Azure DevOps organization to use
.Parameter PAT
    PAT to use when connecting to Azure DevOps
.Parameter OAuthToken
    OAuthToken to use for athentication (e.g. System.AccessToken from build agent)
.Parameter FieldName
    Name of the Work Item Field
.OUTPUTS
    return work item field default value
#>
function Get-WIFieldDefault
{
  param(
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,ParameterSetName='ADOUrl')]
    [string]$ADOUrl,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,ParameterSetName='AccountName')]
    [string]$accountName,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True,ParameterSetName='AccountName')]
    [string]$projectName,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$WorkItemType,
    [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$FieldName,
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

  if ($accountName) {
    $ADOUrl = "https://dev.azure.com/$accountName/$projectName"
  }

  Write-Host "Getting default value for field $FieldName"
  $FieldUrl = "$($ADOUrl)/_apis/wit/workitemtypes/$($WorkItemType)/fields/$($FieldName)?api-version=5.1"
  $Field = Invoke-RestMethod -Method GET -Uri $FieldUrl -Headers $Header
  $Default = $Field.defaultValue
  Write-Host "Default is $Default"
  Return $Default
}
