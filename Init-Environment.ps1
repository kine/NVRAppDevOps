function Init-Environment
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
        $RepoPath=''

    )

    if ($Build -eq '') {
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
                        -memoryLimit 4GB 
    } else {
        $PWord = ConvertTo-SecureString -String 'Pass@word1' -AsPlainText -Force
        $User = $env:USERNAME
        $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User,$PWord
        New-NavContainer -accept_eula `
            -accept_outdated `
            -containerName $ContainerName `
            -imageName $ImageName `
            -licenseFile $LicenseFile `
            -Credential $credentials `
            -auth NavUserPassword `
            -enableSymbolLoading `
            -doNotExportObjectsToText `
            -includeCSide `
            -alwaysPull `
            -includeTestToolkit `
            -additionalParameter ("-v $($RepoPath):c:\app",'-e CustomNavSettings=ServicesUseNTLMAuthentication=true','usessl=n','webclient=n','httpsite=n') 
    #        -myScripts @{"SetupWebClient.ps1"=''} 
    #    -memoryLimit 4GB 
    }
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

    #Add-Type -AssemblyName System.IO.Compression.FileSystem
    #[System.IO.Compression.ZipFile]::ExtractToDirectory($vsixExt,(Joint-Path $vsixpath 'alc'))

    #Import-ObjectsToNavContainer -containerName $ContainerName -objectsFile (Join-Path $PSSCriptRoot 'CALObjects\COD10.txt')
    #Import-ObjectsToNavContainer -containerName $ContainerName -objectsFile (Join-Path $PSSCriptRoot 'CALObjects\COD704.txt')
    #Import-ObjectsToNavContainer -containerName $ContainerName -objectsFile (Join-Path $PSSCriptRoot 'CALObjects\TAB99008535.txt')
    #Compile-ObjectsInNavContainer -containerName $ContainerName -filter 'compiled=0'
}