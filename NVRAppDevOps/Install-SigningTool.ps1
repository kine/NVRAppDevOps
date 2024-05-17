#Inspired by AL-Go code from https://github.com/microsoft/AL-Go/blob/main/Actions/Sign/Sign.psm1
<#
.SYNOPSIS
    Installs the dotnet signing tool.
.DESCRIPTION
    Installs the dotnet signing tool.
.PARAMETER Path
    The path where the signing tool should be installed. Default is the temp folder.
.OUTPUTS
    The path to the signing tool.
#>
function Install-SigningTool {
    param(
        [String]$Path = (Join-Path -Path $($env:TEMP) "SigningTool"),
        [Switch]$Force
    )

    if (Test-Path (Join-Path -Path $Path "sign.exe")) {
        if ($Force) {
            Write-Host "Removing existing signing tool in $Path"
            Remove-Item -Path $Path -Recurse -Force | Out-Null
        }
        else {
            Write-Host "Signing tool already installed in $Path"
            return Join-Path -Path $Path "sign.exe" -Resolve
        }
    }
    else {
        Write-Host "Signing tool not found in $Path, installing..."
    }
    # Get version of the signing tool
    $version = '0.9.1-beta.24123.2'

    # Install the signing tool in the temp folder
    Write-Host "Installing signing tool version $version in $Path"
    New-Item -ItemType Directory -Path $Path | Out-Null
    dotnet tool install sign --version $version --tool-path $Path | Out-Null

    # Return the path to the signing tool
    $signingTool = Join-Path -Path $Path "sign.exe" -Resolve
    return $signingTool
}