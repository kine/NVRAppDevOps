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
.Parameter optionalParameters
    Array of optional Parameters for the container creation
.Parameter useBestContainerOS
    Propagated as useBestContainerOS flag for the New-NAVContainer cmdlet
#>
function Init-ALEnvironment {
    Param (
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $ContainerName,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $ImageName,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $LicenseFile,
        [ValidateSet('', 'process', 'hyperv')]
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $Isolation,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $Build = '',
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $Password = '',
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $RepoPath = '',
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $Username = $env:USERNAME,
        [ValidateSet('Windows', 'NavUserPassword')]
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $Auth = 'Windows',
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $RAM = '4GB',
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [String]$DockerHost,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [PSCredential]$DockerHostCred,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [bool]$DockerHostSSL,
        [switch]$SkipImportTestSuite,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [switch]$TestLibraryOnly,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [bool]$IncludeCSide = $true,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $optionalParameters,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $EnableSymbolLoading = $true,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $CreateTestWebServices = $true,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $customScripts,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $useSSL,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $useBestContainerOS = $true,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $alwaysPull = $false,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $ArtifactUrl

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
    $includeTestLibrariesOnly = (-not $inclTestToolkit) -or $TestLibraryOnly
    if ($Build -ne 'true') {
        if ($Password) {
            Write-Host "Using passed password"
            $PWord = ConvertTo-SecureString -String $Password -AsPlainText -Force
            $User = $Username
            $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
        }
        else {
            if ($Auth -eq 'Windows') {
                $credentials = Get-Credential -Message "Enter your WINDOWS password!!!" -UserName $Username
            }
            else {
                $credentials = Get-Credential -Message "Enter password you want to use" -UserName $Username
            }
        }

        $myscripts = @(@{'MainLoop.ps1' = 'while ($true) { start-sleep -seconds 10 }' })

        if ($customScripts) {
            $myscripts += $customScripts
        }

        if ($RepoPath) {
            $additionalParameters = @("--volume ""$($RepoPath):C:\app""")
        }
        else {
            $additionalParameters = @()
        }

        if ($useSSL -eq 'true') {
            $additionalParameters += "--env useSSL=Y"
        }

        if ($optionalParameters) {
            $additionalParameters += $optionalParameters
        }
        if (-not $ArtifactUrl) {
            if (-not (Get-ContainerImageCurrentness -Image $ImageName)) {
                docker pull $ImageName
            }
        }
        New-BcContainer -accept_eula `
            -accept_outdated `
            -containerName $ContainerName `
            -imageName $ImageName `
            -licenseFile $LicenseFile `
            -isolation $Isolation `
            -Credential $credentials `
            -doNotExportObjectsToText `
            -enableSymbolLoading:$EnableSymbolLoading `
            -includeCSide:$IncludeCSide `
            -includeTestToolkit:$inclTestToolkit `
            -includeTestLibrariesOnly:$includeTestLibrariesOnly `
            -shortcuts "Desktop" `
            -auth $Auth `
            -additionalParameters $additionalParameters `
            -memoryLimit $RAM `
            -assignPremiumPlan `
            -updateHosts `
            -useBestContainerOS:$useBestContainerOS `
            -myScripts $myscripts `
            -alwaysPull:$alwaysPull `
            -artifactUrl $ArtifactUrl 

    }
    else {
        if ((-not $Password) -or ($Password -eq '')) {
            Write-Host 'Using fixed password and NavUserPassword authentication'
            $PWord = ConvertTo-SecureString -String 'Pass@word1' -AsPlainText -Force
        }
        else {
            Write-Host "Using passed password and $Auth authentication"
            $PWord = ConvertTo-SecureString -String $Password -AsPlainText -Force
        }
        $User = $Username
        $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

        if ($customScripts) {
            $myscripts = @($customScripts)
        }
        else {
            $myscripts = @()
        }

        if ($RepoPath) {
            $additionalParameters = @("--volume ""$($RepoPath):C:\app""")
        }
        else {
            $additionalParameters = @()
        }

        if ($useSSL -eq 'true') {
            $additionalParameters += "--env useSSL=Y"
        }
        else {
            $additionalParameters += "--env useSSL=N"
        }

        if ($optionalParameters) {
            $additionalParameters += $optionalParameters
        }
        if (-not $ArtifactUrl) {
            if (-not (Get-ContainerImageCurrentness -Image $ImageName)) {
                docker pull $ImageName
            }
        }
        New-BcContainer -accept_eula `
            -accept_outdated `
            -containerName $ContainerName `
            -imageName $ImageName `
            -licenseFile $LicenseFile `
            -isolation $Isolation `
            -Credential $credentials `
            -auth $Auth `
            -enableSymbolLoading:$EnableSymbolLoading `
            -doNotExportObjectsToText `
            -includeCSide:$IncludeCSide `
            -includeTestToolkit:$inclTestToolkit `
            -includeTestLibrariesOnly:$includeTestLibrariesOnly `
            -additionalParameters $additionalParameters `
            -memoryLimit $RAM `
            -assignPremiumPlan `
            -shortcuts "None" `
            -useBestContainerOS:$useBestContainerOS `
            -updateHosts `
            -myScripts $myscripts `
            -alwaysPull:$alwaysPull `
            -artifactUrl $ArtifactUrl 

        #        -myScripts @{"SetupWebClient.ps1"=''}
        #    -memoryLimit 4GB
    }

    if ($Build -eq '') {
        Write-Host 'Extracting VSIX'
        docker exec -t $ContainerName PowerShell.exe -Command { $targetDir = "c:\run\my\alc"; $vsix = (Get-ChildItem "c:\run\*.vsix" -Recurse | Select-Object -First 1); Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory($vsix.FullName, $targetDir) ; Write-Host "$vsix"; copy-item $vsix "c:\run\my" }

        $vsixExt = (Get-ChildItem "C:\ProgramData\BcContainerHelper\Extensions\$ContainerName\" -Filter *.vsix).FullName
        Write-Host 'Installing vsix package'
        code --install-extension $vsixExt
    }
    
    if ($inclTestToolkit -and $CreateTestWebServices) {
        Write-Host 'Publishing CALTestResult (PAG130405) and CALCodeCoverageMap (PAG130408) Webservices'

        $ServerConfig = Get-BcContainerServerConfiguration -ContainerName $ContainerName

        Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock {
            Param($serverInstance)
            New-NAVWebService -ServerInstance $serverInstance -ServiceName CALTestResults -ObjectType Page -ObjectId 130405 -Published $True
            New-NAVWebService -ServerInstance $serverInstance -ServiceName CALCodeCoverageMap -ObjectType Page -ObjectId 130408 -Published $True 
        } -argumentList $ServerConfig.ServerInstance
    }
}
