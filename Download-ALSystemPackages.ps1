<#
.SYNOPSIS
    Download system app packages
.DESCRIPTION
    Download system app packages from given container
.EXAMPLE
    PS C:\> Read-ALConfiguration -Path .\ | Download-ALSystemPackages -AlPackagesPath <apppath>
    Will read configuration of the AL project and download system packages for it into <apppath> folder
.Parameter ContainerName
    Name of the container to use
.Parameter Build   
    If specified, script will not ask for user name and password to authenticate to container
.Parameter PlatformVersion
    Version for which the apps will be downloaded
.Parameter Password
    If Build is specified, this password will be used to authenticate to container (with user name = current user name)    
.Parameter IncludeTestModule
    If set, the Test app package will be downloaded too
.Parameter AlPackagesPath
    Path to store the app packages into
.Parameter UseDefaultCred
    Use default credentials when downloading the symbols
.Parameter Force
    Download the package even when already exists on disk
#>
function Download-ALSystemPackages
{
    param (
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Build='',
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $PlatformVersion,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Password='Pass@word1',
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Username=$env:USERNAME,
        [ValidateSet('Windows', 'NavUserPassword')]
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Auth='Windows',
        $IncludeTestModule=$False,
        $AlPackagesPath,
        [bool]$UseDefaultCred=$False,
        [switch]$Force
    )

    function Get-AlSymbolFile {
        param(
            
            [Parameter(Mandatory = $false)]
            [String] $Publisher = 'Microsoft',
            [Parameter(Mandatory = $true)]
            [String] $AppName,
            [Parameter(Mandatory = $true)]
            [String] $AppVersion,
            [Parameter(Mandatory = $true)]
            [String] $DownloadFolder,
            [ValidateSet('Windows', 'NavUserPassword')]
            [Parameter(Mandatory = $true)]
            [String] $Authentication='Windows',
            [Parameter(Mandatory = $true)] 
            [pscredential] $Credential ,
            [bool]$UseDefaultCred=$false,
            [bool]$Force
        )

        $TargetFile = Join-Path -Path $DownloadFolder -ChildPath "$($Publisher)_$($AppName)_$($AppVersion).app"

        if ($Force -or (-not (Test-path $TargetFile))) {
            $ServerConfig = Get-BcContainerServerConfiguration -ContainerName $ContainerName

            if ($Authentication -eq 'NavUserPassword') {
                $PasswordTemplate = "$($Credential.UserName):$($Credential.GetNetworkCredential().Password)"
                $PasswordBytes = [System.Text.Encoding]::Default.GetBytes($PasswordTemplate)
                $EncodedText = [Convert]::ToBase64String($PasswordBytes)
                
                $null = Invoke-RestMethod `
                            -Method get `
                            -Uri "http://$($ContainerName):7049/$($ServerConfig.ServerInstance)/dev/packages?publisher=$($Publisher)&appName=$($AppName)&versionText=$($AppVersion)&tenant=default" `
                            -Headers @{ "Authorization" = "Basic $EncodedText"} `
                            -OutFile $TargetFile `
                            -TimeoutSec 600 -Verbose
                
            }  else {
                if ($UseDefaultCred) {
                    $null = Invoke-RestMethod `
                            -Method get `
                            -Uri "http://$($ContainerName):7049/$($ServerConfig.ServerInstance)/dev/packages?publisher=$($Publisher)&appName=$($AppName)&versionText=$($AppVersion)&tenant=default" `
                            -UseDefaultCredentials `
                            -OutFile $TargetFile `
                            -TimeoutSec 600 -Verbose
                } else {
                    $null = Invoke-RestMethod `
                            -Method get `
                            -Uri "http://$($ContainerName):7049/$($ServerConfig.ServerInstance)/dev/packages?publisher=$($Publisher)&appName=$($AppName)&versionText=$($AppVersion)&tenant=default" `
                            -Credential $Credential `
                            -OutFile $TargetFile `
                            -TimeoutSec 600 -Verbose
                }
            }
        }
        Get-Item $TargetFile
    }

    if (-not $AlPackagesPath) {
        $alpackages = (Join-Path $AppPath '.alpackages')
    } else {
        $alpackages = $AlPackagesPath
    }
    if (-not (Test-path $alpackages)) {
        mkdir $alpackages | out-null
    }

    if ($UseDefaultCred) {
        $PWord = ConvertTo-SecureString -String $Password -AsPlainText -Force
        $User = $Username
        $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User,$PWord
    } else {
        if ($Build -eq '') {
            $credentials = Get-Credential -Message "Enter your WINDOWS password!!!" -UserName $Username
        } else {
            $PWord = ConvertTo-SecureString -String $Password -AsPlainText -Force
            $User = $Username
            $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User,$PWord
        }
    }
    Get-AlSymbolFile `
        -AppName 'Application' `
        -AppVersion $PlatformVersion `
        -DownloadFolder $alpackages `
        -Authentication $Auth `
        -Credential $credentials `
        -UseDefaultCred $UseDefaultCred `
        -Force $Force

    Get-AlSymbolFile `
        -AppName 'System' `
        -AppVersion $PlatformVersion `
        -DownloadFolder $alpackages `
        -Authentication $Auth `
        -Credential $credentials `
        -UseDefaultCred $UseDefaultCred `
        -Force $Force

    if ($IncludeTestModule) {
        Get-AlSymbolFile `
        -AppName 'Test' `
        -AppVersion $PlatformVersion `
        -DownloadFolder $alpackages `
        -Authentication $Auth `
        -Credential $credentials `
        -UseDefaultCred $UseDefaultCred `
        -Force $Force
    }
}