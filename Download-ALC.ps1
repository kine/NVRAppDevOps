<#
.SYNOPSIS
    Extract alc.exe from the container
.DESCRIPTION
    Extract alc.exe from the container to be able to compile AL projects
.EXAMPLE
    PS C:\> Read-ALConfiguration -Path .\ | Download-ALC
    Read configuration for the project and downlaod the ALC from configured container
.Parameter ContainerName
    Name of the container to use for downloading the compiler
.Parameter destinationPath
    Path where to copy the container
#>
function Download-ALC
{
    param (
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName,
        $destinationPath=$env:TEMP+'ALC'
    )
    $id = $ContainerName
    $tempFolder = (Join-Path "$env:TEMP" "$id")
    if (-not (Test-Path $destinationPath)) {
        New-Item $destinationPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    }
    $destinationFile = (Join-Path $destinationPath "my.vsix")
    Write-Host "Copying VSIX from container to $destinationFile"



    #New-Item $tempFolder -ItemType Directory | Out-Null
    #docker cp ${id}:c:\run $tempFolder
    #Get-item -Path "$tempFolder\Run*.vsix" | % { Copy-Item -Path $_.FullName -Destination $destinationFile }
    #Remove-Item $tempFolder -Recurse -Force | Out-Null

    #Add-Type -AssemblyName System.IO.Compression.FileSystem
    #[System.IO.Compression.ZipFile]::ExtractToDirectory($destinationFile,$destinationPath)

    Write-Output $destinationFile
}