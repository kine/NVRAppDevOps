function Upload-PerTenantApp
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
        $AppPath,
        $Environment
    )

    #Get token
    Write-Host "Getting OAuth token..."
    $Token = Get-OAuth2 -AppId $AppId -AppSecret $AppSecret -Credentials $Credentials -Tenant $Tenant
    #Get companies
    Write-Host "Getting companies..."
    $Companies = Get-BCAPIData -OAuthToken $Token -Tenant $Tenant -APIUri $APIUri -Query 'companies' -Environment $Environment -APIVersion $APIVersion
    #Upload the app
    $CompanyID = $Companies[0].id
    $CompanyName = $Companies[0].name
    Write-Host "Getting uploading extension to company $CompanyID ($CompanyName)..."
    $AppContent = [IO.File]::ReadAllBytes($AppPath)
    $Result = Patch-BCAPIData -OAuthToken $Token -Tenant $Tenant -APIUri $APIUri -Query "companies($CompanyID)/extensionUpload(0)/content" -Body $AppContent -Environment $Environment -APIVersion $APIVersion
    return $Result
}