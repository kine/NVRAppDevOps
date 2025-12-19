Write-Host "Importing BcContainerHelper module as Global..."
Import-Module BcContainerHelper -DisableNameChecking -Global

$Psd = get-content -Path (Join-Path $PSScriptRoot 'NVRAppDevOps.psd1') -Raw
$ModuleVersion = (invoke-expression $Psd).ModuleVersion
$ModulePrerelease = (invoke-expression $Psd).PrivateData.PSData.Prerelease
Write-Host "NVRAppDevOps version $ModuleVersion $ModulePrerelease"
Write-Verbose  "Reading scripts from $PSScriptRoot"
Get-Item $PSScriptRoot  | Get-ChildItem -Recurse -file -Filter '*.ps1' |  Sort Name | foreach {
    Write-Verbose "Loading $($_.Name)"  
    . $_.fullname
}

Export-ModuleMember -Function *-*
