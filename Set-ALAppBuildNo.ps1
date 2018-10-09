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
#>
function Set-ALAppBuildNo
{
    Param (
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $RepoPath=''
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
    foreach ($App in $Apps) {
        $AppSetup = Get-Content -Path $App.FullName -Encoding UTF8| ConvertFrom-Json
        $Version = [Version]$AppSetup.version
        $Build = Get-NoOfDaysSince20000101
        $Revision = Get-NoOfSecondsSinceMidnight
        $NewVersion = "$($Version.Major).$($Version.Minor).$Build.$Revision"
        $AppSetup.version = $NewVersion
        $AppSetup | ConvertTo-Json -Depth 5 -Compress | Set-Content -Path $App.FullName -Encoding UTF8
        #(Get-Content -Path $App.FullName -Encoding UTF8) -replace ""
    }
}