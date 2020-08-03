function Download-ALPackages
{
    param (
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $AppPath,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $TestAppPath,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $PlatformVersion,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $AppVersion,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $TestAppVersion,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Publisher,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $TestPublisher,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $AppName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $TestAppName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Build='',
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Password='Pass@word1',
        [ValidateSet('Windows', 'NavUserPassword')]
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Auth='Windows',
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Username=$env:USERNAME,
        $AlPackagesPath,
        $TestApp
    )

    #$vsixExt = (Join-Path $env:TEMP 'al.vsix')
    #$vsixURL=docker logs $ContainerName | where-object {$_ -like '*vsix*'} | select-object -first 1

    #Add-Type -AssemblyName System.IO.Compression.FileSystem
    #[System.IO.Compression.ZipFile]::ExtractToDirectory($vsixExt,$vsixpath)

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
            [pscredential] $Credential 
        )

        $TargetFile = Join-Path -Path $DownloadFolder -ChildPath "$($Publisher)_$($AppName)_$($AppVersion).app"
        $ServerConfig = Get-BcContainerServerConfiguration -ContainerName $ContainerName
        
        if ($Authentication -eq 'NavUserPassword') {
            $PasswordTemplate = "$($Credential.UserName):$($Credential.GetNetworkCredential().Password)"
            $PasswordBytes = [System.Text.Encoding]::Default.GetBytes($PasswordTemplate)
            $EncodedText = [Convert]::ToBase64String($PasswordBytes)
            
            $null = Invoke-RestMethod `
                        -Method get `
                        -Uri "http://$($ContainerName):7049/$(ServerConfig.ServerInstance)/dev/packages?publisher=$($Publisher)&appName=$($AppName)&versionText=$($AppVersion)&tenant=default" `
                        -Headers @{ "Authorization" = "Basic $EncodedText"} `
                        -OutFile $TargetFile `
                        -TimeoutSec 600 -Verbose
            
        }  else {
            $null = Invoke-RestMethod `
                        -Method get `
                        -Uri "http://$($ContainerName):7049/$(ServerConfig.ServerInstance)/dev/packages?publisher=$($Publisher)&appName=$($AppName)&versionText=$($AppVersion)&tenant=default" `
                        -Credential $Credential `
                        -OutFile $TargetFile `
                        -TimeoutSec 600 -Verbose
        }

        Get-Item $TargetFile
    }

    if (-not $TestApp) {
        if (-not $AlPackagesPath) {
            $alpackages = (Join-Path $AppPath '.alpackages')
        } else {
            $alpackages = $AlPackagesPath
        }
        if (-not (Test-path $alpackages)) {
            mkdir $alpackages | out-null
        }

        if ($Build -eq '') {
            $credentials = Get-Credential -Message "Enter your WINDOWS password!!!" -UserName $Username
            Get-AlSymbolFile `
                -AppName 'Application' `
                -AppVersion $PlatformVersion `
                -DownloadFolder $alpackages `
                -Authentication $Auth `
                -Credential $credentials   

            Get-AlSymbolFile `
                -AppName 'System' `
                -AppVersion $PlatformVersion `
                -DownloadFolder $alpackages `
                -Authentication $Auth `
                -Credential $credentials  

        } else {
            $PWord = ConvertTo-SecureString -String $Password -AsPlainText -Force
            $User = $Username
            $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User,$PWord
            Get-AlSymbolFile `
                -AppName 'Application' `
                -AppVersion $PlatformVersion `
                -DownloadFolder $alpackages `
                -Authentication $Auth `
                -Credential $credentials   

            Get-AlSymbolFile `
                -AppName 'System' `
                -AppVersion $PlatformVersion `
                -DownloadFolder $alpackages `
                -Authentication $Auth `
                -Credential $credentials  

        }
    } else {
        if ($TestAppName) {
            if (-not $AlPackagesPath) {
                $alpackages = (Join-Path $TestAppPath '.alpackages')
            } else {
                $alpackages = $AlPackagesPath
            }
            if (-not (Test-path $alpackages)) {
                mkdir $alpackages | out-null
            }

            if ($Build -eq '') {
                $credentials = Get-Credential -Message "Enter your WINDOWS password!!!" -UserName $Username
                Get-AlSymbolFile `
                    -AppName 'Application' `
                    -AppVersion $PlatformVersion `
                    -DownloadFolder $alpackages `
                    -Authentication $Auth `
                    -Credential $credentials   

                Get-AlSymbolFile `
                    -AppName 'System' `
                    -AppVersion $PlatformVersion `
                    -DownloadFolder $alpackages `
                    -Authentication $Auth `
                    -Credential $credentials  

                Get-AlSymbolFile `
                    -AppName $AppName `
                    -AppVersion $AppVersion `
                    -DownloadFolder $alpackages `
                    -Authentication $Auth `
                    -Credential $credentials `
                    -Publisher $Publisher

            } else {
                $PWord = ConvertTo-SecureString -String $Password -AsPlainText -Force
                $User = $env:USERNAME
                $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User,$PWord
                Get-AlSymbolFile `
                    -AppName 'Application' `
                    -AppVersion $PlatformVersion `
                    -DownloadFolder $alpackages `
                    -Authentication $Auth `
                    -Credential $credentials   

                Get-AlSymbolFile `
                    -AppName 'System' `
                    -AppVersion $PlatformVersion `
                    -DownloadFolder $alpackages `
                    -Authentication $Auth `
                    -Credential $credentials  

                Get-AlSymbolFile `
                    -AppName $AppName `
                    -AppVersion $AppVersion `
                    -DownloadFolder $alpackages `
                    -Authentication $Auth `
                    -Credential $credentials `
                    -Publisher $Publisher
            }
        }
    }
}