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
        $version
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