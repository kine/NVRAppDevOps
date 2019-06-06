<#
.SYNOPSIS
    Set the build no. in the App.json
.DESCRIPTION
    Set the build no. in the App.json in the app version. It will keep the Major and Minor version no.
    !Warning! It will reformat the App.json. It is recommended to use it only during CI/CD and throw the change away after that.
.EXAMPLE
    PS C:\>  Read-ALConfiguration -Path <repopath> | Set-ALAppBuildNo
    Read the config for the repo and update the build no.
.Parameter RepoPath
    Path to the repository - will be mapped as c:\app into the container
.Parameter UpdateDevOpsBuildNo
    If set, version in the Build Pipeline name will be updated for Azure DevOps build pipeline
.Parameter AppName
    Name of the main app. If app.json for this app is found, the version will be set to the new value.
.Parameter TestAppName
    Name of the test app. If app.json for this app is found, the version will be set to the new value.
.Parameter Filters
    If set, version will be set in all app.json files included in the filter. Example: 'mainapp\\app.json','testapp\\app.json'
    Could be combined with the AppName and TestAppName parameters.
.Parameter Buildno
    If set, value will be used as build no and revison will be 0.

#>
function Set-ALAppBuildNo
{
    Param (
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $RepoPath='',
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $AppName='',
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $TestAppName='',
        [switch]$UpdateDevOpsBuildNo,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Filters,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $BuildNo=''
    )
    function Get-NoOfDaysSince20000101
    {
        $timespan = New-TimeSpan -Start '2000-01-01' -End (Get-Date).ToUniversalTime().ToShortDateString()
        return $timespan.TotalDays
    }
    function Get-NoOfSecondsSinceMidnight
    {
        $seconds = [math]::Round((Get-Date).ToUniversalTime().TimeOfDay.TotalSeconds)
        return $seconds
    }
    $Apps = Get-ChildItem -Path $RepoPath -Filter app.json -Recurse
    if ($BuildNo) {
        $Build = $BuildNo
        $Revision = 0
    } else {
        $Build = Get-NoOfDaysSince20000101
        $Revision = Get-NoOfSecondsSinceMidnight
    }

    $PossibleAppJson = @()
    if ($Filters) {
        foreach($f in $Filters) {
            $PossibleAppJson += (Get-ChildItem -Path (Join-path $RepoPath $f)).FullName.ToLower()
        }
    }
    foreach ($App in $Apps) {
        $AppSetup = Get-Content -Path $App.FullName -Encoding UTF8| ConvertFrom-Json
        if (($AppSetup.name -eq $AppName) -or ($AppSetup.name -eq $TestAppName) -or ($PossibleAppJson.Contains($App.FullName.ToLower()))) 
        {            
            $Version = [Version]$AppSetup.version
            $NewVersion = "$($Version.Major).$($Version.Minor).$Build.$Revision"
            Write-Host "Setting version for $($AppSetup.name) to $NewVersion"
            $AppSetup.version = $NewVersion
            $AppSetup | ConvertTo-Json -Depth 5 -Compress | Set-Content -Path $App.FullName -Encoding UTF8
            if (-not $ReturnVersion) {
                $ReturnVersion = $NewVersion
            }
            #(Get-Content -Path $App.FullName -Encoding UTF8) -replace ""
            if ($UpdateDevOpsBuildNo -and ($AppSetup.name -eq $AppName)) {
                write-host "Updating build pipeline no. to $NewVersion"
                write-host "##vso[build.updatebuildnumber]$NewVersion"
            }
        }
    }
    return $ReturnVersion
}