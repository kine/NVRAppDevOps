<# 
.Synopsis
    Get currentness of a local container image
.Description
    Gets the installed version of a local image 
.Parameter ImageName
    The image name
.Parameter ImageTag
    The image version
.Parameter Image
    The complete image with image name and version
.Parameter Registry
    If you don't want to use the mcr.microsoft.com registry specify with this parameter
.Example
    Get-ContainerImageCurrentness -Image "businesscentral/sandbox:ltsc2019"
.Example
    Get-ContainerImageCurrentness -Image "businesscentral/sandbox:ltsc2019" -Registry "mcr.microsoft.com"
.Example
    Get-ContainerImageCurrentness -ImageName "businesscentral/sandbox" -ImageTag "ltsc2019"
.Example
    Get-ContainerImageCurrentness -ImageName "businesscentral/sandbox" -ImageTag "ltsc2019" -Registry "mcr.microsoft.com"
#>
function Get-ContainerImageCurrentness {
    Param(
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $Image
    )
    $localImageIsLatest = $False;
    if ((($Image -eq "") -or ($null -eq $Image))) {
        Write-Error "You need to either specify Image or ImageName and ImageTag";
    } else {
        # https://regexr.com/4l9vu
        $pattern = [regex]'([--:\w?@%&+~#=]*\.[a-z]{2,4}\/{0,2})((?:[?&](?:\w+)=(?:\w+))+|[--:\w?@%&+~#=]+)?';
        $matches = $Image | Select-String -Pattern $pattern -AllMatches;
        $result = $matches.Matches.Groups[2].Value.Split(':');
        $Registry = $matches.Matches.Groups[1].Value.Split('/')[0];
        $ImageName = $result[0];
        $ImageTag = $result[1];
        $Image = $Registry + "/" + $ImageName + ":" + $ImageTag;
        try {
            $manifestUri = "https://$Registry/v2/$ImageName/manifests/$ImageTag";
            $manifestWebRequest = Invoke-WebRequest -Uri $manifestUri -Method Get;
            $manifestContent = [System.Text.Encoding]::ASCII.GetString($manifestWebRequest.RawContentStream.ToArray());
            $manifestJsonObj = $manifestContent | ConvertFrom-Json;
            $manifestHistory = $manifestJsonObj.history;

            $localImageInspectJson = docker inspect $Image;
            $localImageInspectObj = $localImageInspectJson | ConvertFrom-Json;
            $localImageCreated = $localImageInspectObj.Created;
    
            for ($i = 1; $i -lt $manifestHistory.length; $i++) {
                $manifestCompatibility = $manifestHistory[$i].v1Compatibility | ConvertFrom-Json;
                $manifestCompatibilityCreated = [DateTime]$manifestCompatibility.created;
                $ts = New-TimeSpan -Start $localImageCreated -End $manifestCompatibilityCreated;
                if ($ts.Hours -ge 1) {
                    $localImageIsLatest = $false;
                }
            }
        }
        catch {
            $localImageIsLatest = $false
            Write-Warning "The image $Image could not be found locally";
        }
        finally {        
            if ($localImageIsLatest) {
                Write-Host "The local version of the image $image is the latest version";
            }
            else {
                Write-Host "The local version of the image $image is NOT the latest version";
            }   
        }
    }
    return $localImageIsLatest;
}