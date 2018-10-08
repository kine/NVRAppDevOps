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
        $RAM='4GB',
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [String]$DockerHost,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [PSCredential]$DockerHostCred,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [bool]$DockerHostSSL

    )
    Write-Host "Build is $Build"
    if ($Build -ne 'true') {
        $credentials = Get-Credential -Message "Enter your WINDOWS password!!!" -UserName $env:USERNAME

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
                        -includeTestToolkit `
                        -additionalParameters("-v $($RepoPath):c:\app",'-e CustomNavSettings=ServicesUseNTLMAuthentication=true') `
                        -memoryLimit $RAM `
                        -assignPremiumPlan
    } else {
        if ((-not $Password) -or ($Password -eq '')) {
            Write-Host 'Using fixed password and NavUserPassword authentication'
            $PWord = ConvertTo-SecureString -String 'Pass@word1' -AsPlainText -Force
            $Auth = 'NavUserPassword'
        } else {
            Write-Host "Using passed password and Windows authentication"
            $PWord = ConvertTo-SecureString -String $Password -AsPlainText -Force
            $Auth = 'Windows'
        }
        $User = $env:USERNAME
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
            -includeTestToolkit `
            -additionalParameter ('-e CustomNavSettings=ServicesUseNTLMAuthentication=true','-e usessl=N','-e webclient=N','-e httpsite=N') `
            -memoryLimit $RAM `
            -assignPremiumPlan

    #        -myScripts @{"SetupWebClient.ps1"=''} 
    #    -memoryLimit 4GB 
    }
    #Write-Host 'Compiling Test toolkit objects'
    #Compile-ObjectsInNavContainer -containerName $ContainerName -filter "Version List=*Test*" 
    #$vsixExt = (Join-Path $env:TEMP 'al.vsix')
    #$vsixURL=docker logs $ContainerName | where-object {$_ -like '*vsix*'} | select-object -first 1

    Write-Host 'Extracting VSIX'
    docker exec -t $ContainerName PowerShell.exe -Command {$targetDir = "c:\run\my\alc"; $vsix = (Get-ChildItem "c:\run\*.vsix" -Recurse | Select-Object -First 1);Add-Type -AssemblyName System.IO.Compression.FileSystem;[System.IO.Compression.ZipFile]::ExtractToDirectory($vsix.FullName, $targetDir) ;Write-Host "$vsix";copy-item $vsix "c:\run\my"}


    #Write-Host 'Downloading vsix package'
    #Start-BitsTransfer -Source $vsixURL -Destination $vsixExt
    $vsixExt = (Get-ChildItem "C:\ProgramData\NavContainerHelper\Extensions\$ContainerName\" -Filter *.vsix).FullName

    if ($Build -eq '') {
        Write-Host 'Installing vsix package'
        code --install-extension $vsixExt
    }

}