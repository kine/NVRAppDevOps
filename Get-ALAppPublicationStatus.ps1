function Get-ALAppPublicationStatus
{
    param(
        [parameter(Mandatory = $true)]
        [string]$AppId,
        [parameter(Mandatory = $true)]
        [string]$AppSecret,
        [pscredential]$Credentials=(Get-Credentials -Message "Enter credentials for BC"),
        [parameter(Mandatory = $true)]
        [string]$Tenant,
        $APIUri = 'api/microsoft/automation/beta',
        $APIVersion = 'v1.0',
        $Token,
        $Environment,
        $CompanyID

    )

    if (-not $Token) {
        #Get token
        Write-Host "Getting OAuth token..."
        $Token = Get-OAuth2 -AppId $AppId -AppSecret $AppSecret -Credentials $Credentials -Tenant $Tenant
    }

    if (-not $CompanyID) {
        #Get companies
        Write-Host "Getting companies..."
        $Companies = Get-BCAPIData -OAuthToken $Token -Tenant $Tenant -APIUri $APIUri -Query 'companies' -Environment $Environment -APIVersion $APIVersion
        $CompanyID = $Companies[0].id
    }

    #Upload the app
    Write-Host "Getting last publishing status from company $CompanyID..."
    $Result = Get-BCAPIData -OAuthToken $Token -Tenant $Tenant -APIUri $APIUri -Query "companies($CompanyID)/extensionDeploymentStatus" -Environment $Environment -APIVersion $APIVersion
    $LastStatus = $Result[0]
    Write-Host "Last status: $($LastStatus.name) $($LastStatus.publisher) $($LastStatus.appVersion) $($LastStatus.Status)"
    return $LastStatus
}