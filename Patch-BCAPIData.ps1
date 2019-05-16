function Patch-BCAPIData
{
    <#
    .SYNOPSIS
    Gets data from API
    .DESCRIPTION
    Use the OAuth bearer token and read data from given API
    .PARAMETER OAuthToken
    Result of calling e.g. Get-OAuth2 function
    .PARAMETER APIURI
    URI of the API to call (e.g. 'api/microsoft/automation/beta')
    .PARAMETER Tenant
    Tenant ID and environment name (e.g. 'mytenant' or 'mytenant/Sandbox')
    .PARAMETER Query
    Query part of the URL (e.g. 'companies')
    .PARAMETER Body
    Body of the query (e.g. app filen content)
    .EXAMPLE
    Patch-BCAPIData -OAuthToken $OAuth -APIURI 'api/microsoft/automation/beta' -Tenant 'mytenant/Sandbox' -Query 'companies("companyid")/extensionUpload(0)/content' -Body (Get-Content -Path myapp.app) -ContentType 'application/octet-stream'
    #>
    param(
        [parameter(Mandatory = $true)]
        $OAuthToken,
        [parameter(Mandatory = $true)]
        $APIURI,
        [parameter(Mandatory = $true)]
        $Tenant,
        [parameter(Mandatory = $true)]
        $Query,
        [parameter(Mandatory = $true)]
        $Body,
        $ContentType='application/octet-stream',
        $eTag='*',
        $APIVersion = 'v1.0',
        $Environment = ''
    )
    if ($Environment -ne '') {
        $Tenant = $Tenant + '/' + $Environment
    }

    $Uri = "https://api.businesscentral.dynamics.com/$APIVersion/$Tenant/$APIURI/$Query"
    $Headers = @{
        Authorization = $OAuthToken.token_type + " " + $OAuthToken.access_token
        'Content-Type' = $ContentType
        'If-Match' = $eTag
    }
    Write-Verbose "PATCH $Uri"
    $Result = Invoke-RestMethod -Method Patch -Uri $Uri -Headers $Headers -Body $Body
    return $Result.value

}