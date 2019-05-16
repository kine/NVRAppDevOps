function Get-BCAPIData
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
    .EXAMPLE
    Get-BCAPIData -OAuthToken $OAuth -APIURI 'api/microsoft/automation/beta' -Tenant 'mytenant/Sandbox' -Query 'companies'
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
        $APIVersion = 'v1.0',
        $Environment=''
    )

    if ($Environment -ne '') {
        $Tenant = $Tenant + '/' + $Environment
    }
    $Uri = "https://api.businesscentral.dynamics.com/$APIVersion/$Tenant/$APIURI/$Query"
    $Headers = @{
        Authorization = $OAuthToken.token_type + " " + $OAuthToken.access_token
    }
    Write-Verbose "GET $Uri"
    $Result = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers
    return $Result.value

}