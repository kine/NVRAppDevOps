function Get-OAuth2 
{
    <#
    .SYNOPSIS
    Gets bearer access token 
    .DESCRIPTION
    Uses Office 365 Application ID and Application Secret to generate the token
    .PARAMETER AppId
    Microsoft Azure Application ID.
    .PARAMETER AppSecret
    Microsoft Azure Application secret.
    .PARAMETER Credentials
    Username and password of the user to authenticate
    #>
    Param (
        [parameter(Mandatory = $true)]
        [string]$AppId,

        [parameter(Mandatory = $true)]
        [string]$AppSecret,

        [parameter(Mandatory = $true)]
        [pscredential]$Credentials,
        [parameter(Mandatory = $true)]
        [string]$Tenant,
        [string]$Resource='https://api.businesscentral.dynamics.com'
    )

    $Uri = "https://login.microsoftonline.com/$Tenant/oauth2/token"
    $Body = @{
        resource = $Resource
        grant_type = 'password'
        username = $Credentials.UserName
        password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credentials.Password))
        client_id = $AppId
        client_secret = $AppSecret
    }
    $AuthResult = Invoke-RestMethod -Method Post -Uri $Uri -Body $Body
    #Function output
    return $AuthResult
}