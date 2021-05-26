<#
.SYNOPSIS
    Function to upload file to sharepoint through sharepoint REST API
.DESCRIPTION
    Upload file to sharepoint through REST API and set metadata for the file
.EXAMPLE
    PS C:\> Upload-FileToShp -File test.txt -Url "https://myshp.com/siteA" -Library MyLib -Metadata @{Title="Some title";MyField="Field value"} -UseDefaultCred
    Takes file test.txt, upload it into https://myshp.com/siteA/MyLib library and set Title to Some title and custom field MyField to FieldValue using default credentials
  
#>
function Upload-FileToShp
{
    param(
        $File,
        $Url,
        $Library,
        [switch]$UseDefaultCred,
        [pscredential]$Cred,
        [hashtable]$Metadata,
        [switch]$Checkin
    )
    #Upload File
    if ($UseDefaultCred) {
        $CredParam = @{"UseDefaultCredentials"=$true}
    } else {
        $CredParam = @{"Credential"=$Cred}
    }
    Write-Host "Getting digest for $Url"
    $Response = Invoke-RestMethod -Method post -uri "$Url/_api/contextinfo" -DisableKeepAlive @CredParam
    $Digest = $response.getcontextwebinformation.FormDigestValue
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $Headers.Add("accept","application/json;odata=verbose")
    $Headers.Add("X-RequestDigest",$Digest)
    $Headers.add("content-length",$FileContent.length)
    $FileName = Split-Path -Path $File -Leaf
    Write-Host "Uploading file to $Url $Library"
    Invoke-RestMethod -method post -uri "$Url/_api/web/GetFolderByServerRelativeUrl('$Library')/files/add(overwrite=true,url='$FileName')" -infile $File -headers $Headers -DisableKeepAlive @CredParam
    
    #modify Metadata
    Write-Host "Updating metadata"
    $body  = ($Metadata | ConvertTo-Json -Depth 4 )
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $Headers.Add("Accept","application/json")
    $Headers.Add("Accept-Encoding","gzip, deflate, br")
    $Headers.Add("X-RequestDigest",$Digest)
    $Headers.add("X-HTTP-Method","PATCH")
    $Headers.Add("IF-MATCH",'*')
    $Headers.Add("Content-Type","application/json;odata=verbose;charset=utf-8")
   
    Invoke-RestMethod -method post -uri "$Url/_api/web/GetFolderByServerRelativeUrl('$Library')/files('$FileName')/listitemallfields" -headers $Headers -Body $body -ContentType 'application/json;charset=utf-8' @CredParam

    #CheckIn
    if ($CheckIn) {
        Write-Host "Checking in the file"
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $Headers.Add("X-RequestDigest",$Digest)
        Invoke-RestMethod -method GET -uri "$Url/_api/web/GetFolderByServerRelativeUrl('$Library')/files('$FileName')/CheckIn(checkintype=0)" -headers $Headers -DisableKeepAlive @CredParam
    }
}