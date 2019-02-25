<#
.SYNOPSIS
    Search for Json with settings and set them as variables
.DESCRIPTION
    Read all *.json files in the folder tree and if it includes configuration, it will set the paamtes as variables
    to be used in Get-ALConfiguration cmdlet

    This cmdlet is used internally inside Read-ALConfiguration cmdlet
#>
function Read-ALJsonConfiguration
{
    [CmdletBinding()]
    Param(
        #Path to the repository
        $Path='.\',
        $SettingsFileName,
        $Profile='default'
    )

    function Get-ValueForConfig
    {
        Param(
            $Text
        )
        if (Test-Path $Text -ErrorAction SilentlyContinue) {
            return $Text
        }
        try {
            $Result = Invoke-Expression -Command $Text -ErrorAction SilentlyContinue
            Write-Verbose "$Text executed and result is $Result"
            return $Result
        } catch {
            Write-Verbose "$Text will be expanded"
            return $ExecutionContext.InvokeCommand.ExpandString($Text)
        }
    }
    function Use-JsonFile
    {
        Param(
            $Json,
            $Profile='default'
        )
        Write-Verbose "Reading profile $Profile from $Json"
        $Config = $JSon.$Profile
        foreach($Property in ($Config | Get-Member -MemberType NoteProperty)) {
            Write-Verbose "Creating global variable $($Property.Name) with value $($Config.$($Property.Name))"
            New-Variable -Name $Property.Name -Value (Get-ValueForConfig $Config.$($Property.Name)) -Visibility Public -Scope Global -Force
        }
    }

    if ($SettingsFileName) {
        $Path = Join-Path $Path $SettingsFileName
    }
    $JsonList = Get-ChildItem -Path $Path -Recurse -Filter *.json

    foreach($JsonFile in $JsonList) {
        Push-Location
        try {
            $Json = Get-Content -Path $JsonFile.PSPath | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($Json -and $Json.default -and $Json.default.ContainerName) {
                Set-Location -Path $JsonFile.DirectoryName
                if ($Profile -ne 'default') {
                    Use-JsonFile -Json $Json -Profile 'default'
                }
                Use-JsonFile -Json $Json -Profile $Profile
            }
        } catch
        {

        }
        Pop-Location
    }
}