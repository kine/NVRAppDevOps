#Inspired by AL-Go code from https://github.com/microsoft/AL-Go/blob/main/Actions/Sign/Sign.psm1
<#
.SYNOPSIS
    Sign the app files with certificate from KeyVault
.DESCRIPTION
    Sign the app files with certificate from KeyVault
.EXAMPLE
    Sign-ALAppsAzure -AppFiles @('c:\AL\Myapp.app','c:\AL\Myapp2.app') -KeyVaultName 'xxxx' -CertificateName -Description -DescriptionUrl -TimestampService -DigestAlgorithm -Verbosity 
    
    Sign the Myapp.app with certificate downloaded from the URL and using password Pass@word1

.PARAMETER AppFiles
    Array of paths to the .app files to sign
.PARAMETER KeyVaultName
    Name of the KeyVault
.PARAMETER CertificateName
    Name of the certificate in the KeyVault
.PARAMETER Description
    Signature decription
.PARAMETER DescriptionUrl
    URL for signature description
.PARAMETER TimestampService
    URL for timestamp service
.PARAMETER DigestAlgorithm
    Digest algorithm to use
.PARAMETER Verbosity
    Verbosity level for the signing
#>

function Sign-ALAppsAzure {
    param(
        [Parameter(Mandatory = $True)]
        [string[]]$AppFiles,
        [Parameter(Mandatory = $True)]
        [string] $KeyVaultName,
        [Parameter(Mandatory = $True)]
        [string] $CertificateName,
        [Parameter(Mandatory = $true)]
        [string] $ClientId,
        [Parameter(Mandatory = $true)]
        [string] $ClientSecret,
        [Parameter(Mandatory = $true)]
        [string] $TenantId,
        [Parameter(Mandatory = $True)]
        [string] $Description,
        [Parameter(Mandatory = $True)]
        [string] $DescriptionUrl,
        [Parameter(Mandatory = $false)]
        [string] $TimestampService = "http://timestamp.digicert.com",
        [Parameter(Mandatory = $false)]
        [string] $DigestAlgorithm = "sha256",
        [Parameter(Mandatory = $false)]
        [string] $Verbosity = "Information"
    ) 
    $SigningToolPath = (Join-Path -Path $($env:TEMP) "SigningTool")
    $SigningToolExe = Install-SigningTool -Path $SigningToolPath

    # Sign files
    . $SigningToolExe code azure-key-vault `
        --azure-key-vault-url "https://$KeyVaultName.vault.azure.net/" `
        --azure-key-vault-certificate $CertificateName `
        --azure-key-vault-client-id $ClientId `
        --azure-key-vault-client-secret $ClientSecret `
        --azure-key-vault-tenant-id $TenantId `
        --description $Description `
        --description-url $DescriptionUrl `
        --file-digest $DigestAlgorithm `
        --timestamp-digest $DigestAlgorithm `
        --timestamp-url $TimestampService `
        --verbosity $Verbosity `
        $FilesToSign
}