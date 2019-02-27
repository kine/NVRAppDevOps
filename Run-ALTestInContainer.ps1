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
 .Example
  Run-ALTestInContainer -ContatinerName test
#>
function Run-ALTestInContainer
{
    param(
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
        $ContainerName=$env:ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Password='',
        [ValidateSet('Windows', 'NavUserPassword')]
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Auth='Windows',
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
        [string]$tenant = "default",
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
        [string] $testSuite = "DEFAULT",
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
        [string] $XUnitResultFileName,
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
        [ValidateSet('no','error','warning')]
        [string] $AzureDevOps = 'no',
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
        [switch] $detailed
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
            $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User,$PWord
        } else {
            if ($Auth -eq 'Windows') {
                $credentials = $null
            } else {
                $credentials = Get-Credential -Message "Enter password you want to use" -UserName $Username
            }
        }
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
    }

    Write-Host "Running tests in container through navcontainerhelper..."
    Run-TestsInNavContainer -containerName $ContainerName -tenant $tenant -credential $credentials -testSuite $testSuite -XUnitResultFileName $XUnitResultFileName -AzureDevOps $AzureDevOps -detailed:$detailed
    
}