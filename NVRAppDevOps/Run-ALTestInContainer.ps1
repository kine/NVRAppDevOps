<# 
 .Synopsis
  Run a test suite in a container
 .Description

 .Parameter containerName
  Name of the container in which you want to run a test suite
 .Parameter tenant
  tenant to use if container is multitenant
 .Parameter credential
  Credentials of the NAV SUPER user if using NavUserPassword authentication
 .Parameter testSuite
  Name of test suite to run. Default is DEFAULT.
 .Parameter XUnitResultFileName
  Credentials of the NAV SUPER user if using NavUserPassword authentication
 .Parameter AzureDevOps
  Generate Azure DevOps Pipeline compatible output. This setting determines the severity of errors.
 .Parameter AppID
  Run all tests defined in app with this AppID (adding tests to test suite is not needed) 
 .Example
  Run-ALTestInContainer -ContatinerName test
#>
function Run-ALTestInContainer {
    param(
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $True)]
        $ContainerName = $env:ContainerName,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $Username = $env:USERNAME,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $Password = '',
        [ValidateSet('Windows', 'NavUserPassword')]
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $Auth = 'Windows',
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $True)]
        [string]$tenant = "default",
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $True)]
        [string] $testSuite = "DEFAULT",
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $True)]
        [string] $XUnitResultFileName,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $True)]
        [ValidateSet('no', 'error', 'warning')]
        [string] $AzureDevOps = 'no',
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $True)]
        [switch]$detailed,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $True)]
        [switch]$restartContainerAndRetry,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $True)]
        [string]$extensionId = '',
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $True)]
        [string]$companyName = '',
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $True)]
        [switch]$returnTrueIfAllPassed
    )
    if ($env:TF_BUILD) {
        Write-Host "TF_BUILD set, running under agent, enforcing Build flag"
        $Build = 'true'
    }

    if ($Build -ne 'true') {
        if ($Password) {
            Write-Host "Using passed password"
            $PWord = ConvertTo-SecureString -String $Password -AsPlainText -Force
            $User = $Username
            $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
        }
        else {
            if ($Auth -eq 'Windows') {
                $credentials = $null
            }
            else {
                $credentials = Get-Credential -Message "Enter password you want to use" -UserName $Username
            }
        }
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
    }

    Write-Host "Running tests in container through bccontainerhelper..."
    $Retry = $true
    while ($true) {
        try {
            Run-TestsInBcContainer `
                -containerName $ContainerName `
                -tenant $tenant `
                -credential $credentials `
                -testSuite $testSuite `
                -XUnitResultFileName $XUnitResultFileName `
                -AzureDevOps $AzureDevOps `
                -detailed:$detailed `
                -restartContainerAndRetry:$restartContainerAndRetry `
                -extensionId $extensionId `
                -companyName $companyName `
                -returnTrueIfAllPassed:$returnTrueIfAllPassed
            break
        }
        catch {
            if (($_.Exception.Message -like "*Connecting to remote server*") -and ($Retry -eq $true)) {
                Write-Host "Retrying to run the test, because last connection to the host failed. This can happen if the script tries restarting the container and the container is not yet ready for WinRM connection after 5 second."
                $Retry = $false
            }
            else {
                throw $_.Exception.Message
            }
        }
    }
        
}