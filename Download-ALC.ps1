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