function PublishNVRAppDevOpsModule
{
    UnRegister-PSRepository -Name "NVRTools"
    $cred = Get-Credential
    Register-PSRepository -Name "NVRTools" -SourceLocation "https://navertica.pkgs.visualstudio.com/_packaging/NVRTools/nuget/v2" -PublishLocation "https://navertica.pkgs.visualstudio.com/_packaging/NVRTools/nuget/v2" -Credential $cred -InstallationPolicy Trusted -Verbose
    nuget sources add -Name NVRTools -Source 'https://navertica.pkgs.visualstudio.com/_packaging/NVRTools/nuget/v2' -Username 'xxx@navertica.com' -Password xxx
    publish-module -Path .\ -Repository NVRTools -NuGetApiKey VSTS -Credential $cred
}