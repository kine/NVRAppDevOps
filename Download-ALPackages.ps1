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
        $Password='',
        $TestApp
    )
    . (Join-Path $PSSCriptRoot 'Settings.ps1')

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

        if ($Authentication -eq 'NavUserPassword') {
            $PasswordTemplate = "$($Credential.UserName):$($Credential.GetNetworkCredential().Password)"
            $PasswordBytes = [System.Text.Encoding]::Default.GetBytes($PasswordTemplate)
            $EncodedText = [Convert]::ToBase64String($PasswordBytes)
            
            $null = Invoke-RestMethod `
                        -Method get `
                        -Uri "http://$($ContainerName):7049/nav/dev/packages?publisher=$($Publisher)&appName=$($AppName)&versionText=$($AppVersion)&tenant=default" `
                        -Headers @{ "Authorization" = "Basic $EncodedText"} `
                        -OutFile $TargetFile `
                        -TimeoutSec 600 -Verbose
            
        }  else {
            $null = Invoke-RestMethod `
                        -Method get `
                        -Uri "http://$($ContainerName):7049/nav/dev/packages?publisher=$($Publisher)&appName=$($AppName)&versionText=$($AppVersion)&tenant=default" `
                        -Credential $credentials `
                        -OutFile $TargetFile `
                        -TimeoutSec 600 -Verbose
        }

        Get-Item $TargetFile
    }

    if (-not $TestApp) {
        $alpackages = (Join-Path $AppPath '.alpackages')
        if (-not (Test-path $alpackages)) {
            mkdir $alpackages | out-null
        }

        if ($Build -eq '') {
            $credentials = Get-Credential -Message "Enter your WINDOWS password!!!" -UserName $env:USERNAME
            Get-AlSymbolFile `
                -AppName 'Application' `
                -AppVersion $AppVersion `
                -DownloadFolder $alpackages `
                -Authentication 'Windows' `
                -Credential $credentials   

            Get-AlSymbolFile `
                -AppName 'System' `
                -AppVersion $AppVersion `
                -DownloadFolder $alpackages `
                -Authentication 'Windows' `
                -Credential $credentials  

        } else {
            $PWord = ConvertTo-SecureString -String 'Pass@word1' -AsPlainText -Force
            $User = $env:USERNAME
            $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User,$PWord
            Get-AlSymbolFile `
                -AppName 'Application' `
                -AppVersion $AppVersion `
                -DownloadFolder $alpackages `
                -Authentication 'NavUserPassword' `
                -Credential $credentials   

            Get-AlSymbolFile `
                -AppName 'System' `
                -AppVersion $AppVersion `
                -DownloadFolder $alpackages `
                -Authentication 'NavUserPassword' `
                -Credential $credentials  

        }
    } else {
        if ($TestAppJSON) {
            $alpackages = (Join-Path $TestAppPath '.alpackages')
            if (-not (Test-path $alpackages)) {
                mkdir $alpackages | out-null
            }

            if ($Build -eq '') {
                $credentials = Get-Credential -Message "Enter your WINDOWS password!!!" -UserName $env:USERNAME
                Get-AlSymbolFile `
                    -AppName 'Application' `
                    -AppVersion $AppVersion `
                    -DownloadFolder $alpackages `
                    -Authentication 'Windows' `
                    -Credential $credentials   

                Get-AlSymbolFile `
                    -AppName 'System' `
                    -AppVersion $AppVersion `
                    -DownloadFolder $alpackages `
                    -Authentication 'Windows' `
                    -Credential $credentials  

                Get-AlSymbolFile `
                    -AppName $AppName `
                    -AppVersion $AppVersion `
                    -DownloadFolder $alpackages `
                    -Authentication 'Windows' `
                    -Credential $credentials `
                    -Publisher $Publisher

            } else {
                $PWord = ConvertTo-SecureString -String 'Pass@word1' -AsPlainText -Force
                $User = $env:USERNAME
                $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User,$PWord
                Get-AlSymbolFile `
                    -AppName 'Application' `
                    -AppVersion $AppVersion `
                    -DownloadFolder $alpackages `
                    -Authentication 'NavUserPassword' `
                    -Credential $credentials   

                Get-AlSymbolFile `
                    -AppName 'System' `
                    -AppVersion $AppVersion `
                    -DownloadFolder $alpackages `
                    -Authentication 'NavUserPassword' `
                    -Credential $credentials  

                Get-AlSymbolFile `
                    -AppName $AppName `
                    -AppVersion $AppVersion `
                    -DownloadFolder $alpackages `
                    -Authentication 'NavUserPassword' `
                    -Credential $credentials `
                    -Publisher $Publisher
            }
        }
    }
}