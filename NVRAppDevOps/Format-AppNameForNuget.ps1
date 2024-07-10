<#
.SYNOPSIS
    Takes all parameters and will return NuGet package id for the info based on the Unified naming rules

.DESCRIPTION
    Takes all parameters and will return NuGet package id for the info based on the Unified naming rules

.EXAMPLE
    PS C:\>  Format-AppNameForNuget -appname 'MyApp' -publisher 'me' -version '1.0.0' -id '12345678-1234-1234-1234-123456789012'
    Result: me.MyApp.12345678-1234-1234-1234-123456789012
    
.PARAMETER appname
    Name of the app to use for the NuGet package id

.PARAMETER publisher
    Publisher of the app to use for the NuGet package id

.PARAMETER version  
    Version of the app to use for the NuGet package id

.PARAMETER id
    Id of the app to use for the NuGet package id

.PARAMETER tag  
    Tag of the app to use for the NuGet package id. Could be localization tag (W1, DK, DE, US, etc.) or "Symbols"

.PARAMETER version
    Version of the app to use for the NuGet package id
#>
function Format-AppNameForNuget {
    Param(
        [Parameter(Mandatory, ParameterSetName = 'OnlyName', Position = 0)]
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $Name,
        [Parameter(Mandatory, ParameterSetName = 'UnifiedNaming')]
        $appname,
        [Parameter(Mandatory, ParameterSetName = 'UnifiedNaming')]
        $publisher,
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        $id,
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        $tag,
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        $version,
        #Sources in format of paket.dependencies file sources to check for the package ID to find the correct package name
        [Parameter(ParameterSetName = 'UnifiedNaming')]
        $NuGetSources = $env:NVRAppDevOpsNugetFeedUrl 
    )
    #Taken from bccontainerhelper PR until it is available in the bccontainerhelper
    function Get-BcNuGetPackageIdTemp {
        Param(
            [Parameter(Mandatory = $false)]
            [string] $packageIdTemplate = '{publisher}.{name}.{tag}.{id}',
            [Parameter(Mandatory = $true)]
            [string] $publisher,
            [Parameter(Mandatory = $true)]
            [string] $name,
            [Parameter(Mandatory = $false)]
            [string] $id = '',
            [Parameter(Mandatory = $false)]
            [string] $tag = '',
            [Parameter(Mandatory = $false)]
            [string] $version = ''
        )
    
        if ($id) {
            try { $id = ([GUID]::Parse($id)).Guid } catch { throw "App id must be a valid GUID: $id" }
        }
        $nname = $name -replace '[^a-zA-Z0-9_\-]', ''
        $npublisher = $publisher -replace '[^a-zA-Z0-9_\-]', ''
        if ($nname -eq '') { throw "App name is invalid: '$name'" }
        if ($npublisher -eq '') { throw "App publisher is invalid: '$publisher'" }
    
        $packageIdTemplate = $packageIdTemplate.replace('{id}', $id).replace('{publisher}', $npublisher).replace('{tag}', $tag).replace('{version}', $version).replace('..', '.').TrimEnd('.')
        # Max. Length of NuGet Package Id is 100 - we shorten the name part of the id if it is too long
        $packageId = $packageIdTemplate.replace('{name}', $nname)
        if ($packageId.Length -ge 100) {
            if ($nname.Length -gt ($packageId.Length - 99)) {
                $nname = $nname.Substring(0, $nname.Length - ($packageId.Length - 99))
            }
            else {
                throw "Package id is too long: $packageId, unable to shorten it"
            }
            $packageId = $packageIdTemplate.replace('{name}', $nname)
        }
        return $packageId
    }
    if ($tag -ieq 'W1') {
        $tag = ''
    }
    if ($NuGetSources -and $id) {
        foreach ($Source in $NuGetSources) {
            Write-Verbose "Checking feed $Source for package id $id"
            #https://navertica.pkgs.visualstudio.com/_packaging/BCApps_Unified/nuget/v3/index.json username:"" password:"%PAT%" authmethod:basic
            $Parts = $Source -split ' '
            $SourceUrl = $Parts[0]
            $Username = ($Parts | Where-Object { $_ -match 'Username:"?(\w*)"?' }).Remove(0, 9).Trim('"')
            $Password = ($Parts | Where-Object { $_ -match 'Password:"?(\w*)"?' }).Remove(0, 9).Trim('"')
            $authmethod = ($Parts | Where-Object { $_ -match 'authmethod:"?(\w*)"?' }).Remove(0, 11).Trim('"')
            If (($Password[0] -eq '%') -and ($Password[$Password.Length - 1] -eq '%')) {
                $VarName = $Password.Trim('%')
                $Password = (Get-Item -Path env:\$VarName).Value
            }
            $PackageName = Find-NuGetPackageNameFromFeed -FeedUrl $SourceUrl -AuthMode $authmethod -Username $Username -Password $Password -PackageFilter $id
            if ($PackageName) {
                Write-Verbose "Package id found in feed $($Source): $PackageName"
                return $PackageName
            }
        }
    }
    if ($appname) {
        if ($appname -eq 'Platform') {
            $id = ''
            $tag = ''
        }
        if ($appname -eq 'Application') {
            $id = ''
        }
        $NuGetId = ''
        try {
            Write-Verbose "Calling Get-BcNuGetPackageId from bccontainerhelper if exists"
            $NuGetId = Get-BcNuGetPackageId -publisher $publisher -name $appname -id $id -tag $tag -version $version
        }
        catch {
            Write-Verbose "Calling Get-BcNuGetPackageIdTemp instead"
            $NuGetId = Get-BcNuGetPackageIdTemp -publisher $publisher -name $appname -id $id -tag $tag -version $version
        }
    }
    else {
        $NuGetId = $Name -replace '\s', '_' -replace '&', '_' -replace '\(', '_' -replace '\)', '_' -replace '/', '_'
    }
    Write-Verbose "NuGetId: $NuGetId"
    return $NuGetId
}