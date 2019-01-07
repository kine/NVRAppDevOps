<#
.SYNOPSIS
    Create container for the AL project
.DESCRIPTION
    Create container for the AL project
.EXAMPLE
    PS C:\>  Read-ALConfiguration -Path <repopath> | Init-ALEnvironment
    Read the config for the repo and create the environment
.Parameter ContainerName
    Name of the container to create
.Parameter ImageName
    Name of the docker image to use
.Parameter LicenseFile
    Path of the .flf file to use
.Parameter Build
    If specified, password will be taken from parameter and not asked from user
.Parameter Password
    Password to use for creating the user inside the container
.Parameter RepoPath
    Path to the repository - will be mapped as c:\app into the container
.Parameter RAM
    Size of RAM for the container (e.g. '4GB')
.Parameter SkipImportTestSuite
    Will not import test suite and it could be imported later through separate command
#>
function Init-ALEnvironment
{
    Param (
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ImageName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $LicenseFile,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Build='',
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Password='',
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $RepoPath='',
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Username=$env:USERNAME,
        [ValidateSet('Windows', 'NavUserPassword')]
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Auth='Windows',
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $RAM='4GB',
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [String]$DockerHost,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [PSCredential]$DockerHostCred,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [bool]$DockerHostSSL,
        [switch]$SkipImportTestSuite

    )
    if ($env:TF_BUILD) {
        Write-Host "TF_BUILD set, running under agent, enforcing Build flag"
        $Build = 'true'
    }

    Write-Host "Build is $Build"
    $inclTestToolkit = $True
    if ($SkipImportTestSuite) {
        $inclTestToolkit = $False
    }
    if ($Build -ne 'true') {
        if ($Password) {
            Write-Host "Using passed password"
            $PWord = ConvertTo-SecureString -String $Password -AsPlainText -Force
            $User = $Username
            $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User,$PWord
        } else {
            if ($Auth -eq 'Windows') {
                $credentials = Get-Credential -Message "Enter your WINDOWS password!!!" -UserName $Username
            } else {
                $credentials = Get-Credential -Message "Enter password you want to use" -UserName $Username
            }
        }
        $myscripts = @(@{'MainLoop.ps1' = 'while ($true) { start-sleep -seconds 10 }'})

        New-NavContainer -accept_eula `
                        -accept_outdated `
                        -containerName $ContainerName `
                        -imageName $ImageName `
                        -licenseFile $LicenseFile `
                        -Credential $credentials `
                        -doNotExportObjectsToText `
                        -enableSymbolLoading `
                        -includeCSide `
                        -alwaysPull `
                        -includeTestToolkit:$inclTestToolkit `
                        -shortcuts "Desktop" `
                        -auth $Auth `
                        -additionalParameters @("--volume ""$($RepoPath):C:\app""",'-e CustomNavSettings=ServicesUseNTLMAuthentication=true') `
                        -memoryLimit $RAM `
                        -assignPremiumPlan `
                        -updateHosts `
                        -useBestContainerOS `
                        -myScripts $myscripts 

    } else {
        if ((-not $Password) -or ($Password -eq '')) {
            Write-Host 'Using fixed password and NavUserPassword authentication'
            $PWord = ConvertTo-SecureString -String 'Pass@word1' -AsPlainText -Force
        } else {
            Write-Host "Using passed password and Windows authentication"
            $PWord = ConvertTo-SecureString -String $Password -AsPlainText -Force
        }
        $User = $Username
        $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User,$PWord
        New-NavContainer -accept_eula `
            -accept_outdated `
            -containerName $ContainerName `
            -imageName $ImageName `
            -licenseFile $LicenseFile `
            -Credential $credentials `
            -auth $Auth `
            -enableSymbolLoading `
            -doNotExportObjectsToText `
            -includeCSide `
            -alwaysPull `
            -includeTestToolkit:$inclTestToolkit `
            -additionalParameters @("--volume ""$($RepoPath):C:\app""",'-e CustomNavSettings=ServicesUseNTLMAuthentication=true','-e usessl=N','-e webclient=N','-e httpsite=N') `
            -memoryLimit $RAM `
            -assignPremiumPlan `
            -shortcuts "None" `
            -useBestContainerOS `
            -updateHosts

    #        -myScripts @{"SetupWebClient.ps1"=''} 
    #    -memoryLimit 4GB 
    }

    if ($Build -eq '') {
    Write-Host 'Extracting VSIX'
    docker exec -t $ContainerName PowerShell.exe -Command {$targetDir = "c:\run\my\alc"; $vsix = (Get-ChildItem "c:\run\*.vsix" -Recurse | Select-Object -First 1);Add-Type -AssemblyName System.IO.Compression.FileSystem;[System.IO.Compression.ZipFile]::ExtractToDirectory($vsix.FullName, $targetDir) ;Write-Host "$vsix";copy-item $vsix "c:\run\my"}

    $vsixExt = (Get-ChildItem "C:\ProgramData\NavContainerHelper\Extensions\$ContainerName\" -Filter *.vsix).FullName
        Write-Host 'Installing vsix package'
        code --install-extension $vsixExt
    }

}