function Find-NuGetPackageNameFromFeed {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeedUrl,
        [string]$AuthMode,
        [string]$Username,
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [string]$PackageFilter
    )
    $AuthParams = @{}
    if ($AuthMode) {
        if ($Username -eq '') {
            $Username = ' '
        }
        $AuthParams = @{
            "Authentication" = $AuthMode
            "Credential"     = new-object System.Management.Automation.PSCredential($Username, (ConvertTo-SecureString $Password -AsPlainText -Force))
        }
    }
    Write-Verbose "Resolving search service from feed manifest on $FeedUrl $AuthMode $Username $Password"
    $Manifest = Invoke-RestMethod -Uri $FeedUrl -Method Get @AuthParams
    if ($Manifest.resources) {
        $SearchUrl = $Manifest.resources | Where-Object { $_.'@type' -like 'SearchQueryService*' } | Select-Object -ExpandProperty '@id'
        Write-Verbose "Search Service found in feed manifest on $SearchUrl"
    }
    else {
        Write-Host "Search Service not found in feed manifest on $FeedUrl"
        return
    }
    $uriRequest = [System.UriBuilder]$SearchUrl
    $QueryString = $PackageFilter
    $Params = [System.Web.HttpUtility]::ParseQueryString($uriRequest.Query)
    $Params.Add("q", $QueryString)
    $uriRequest.Query = $Params.ToString()
    $checkFeedUrlWithQuery = $uriRequest.Uri.ToString()
    Write-Host "Resolving package name from feed for $PackageFilter"
    $Packages = Invoke-RestMethod -Uri $checkFeedUrlWithQuery -Method Get @AuthParams
    Write-Verbose ($Packages | convertto-json -Depth 10)
    if ($Packages.Data.Count -eq 1) {
        $NuGetId = $Packages.data.id
        Write-Verbose "NuGetId from feed: $NuGetId"
        return $NuGetId
    }
    elseif ($Packages.Data.Count -gt 1) {
        Write-Verbose "Multiple packages found in feed for $PackageFilter, skipping the validation"
    }

}