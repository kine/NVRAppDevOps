function PublishNVRAppDevOpsModule
{
    UnRegister-PSRepository -Name "NVRTools"
    $cred = Get-Credential
    #6izkrrrwe74itisdxdvdkdvczl2ew5zkmq2dbj2jkr7nt3spaana
    Register-PSRepository -Name "NVRTools" -SourceLocation "https://navertica.pkgs.visualstudio.com/_packaging/NVRTools/nuget/v2" -PublishLocation "https://navertica.pkgs.visualstudio.com/_packaging/NVRTools/nuget/v2" -Credential $cred -InstallationPolicy Trusted -Verbose
    #Register-PSRepository -Name "NVRTools" -SourceLocation "https://navertica.pkgs.visualstudio.com/_packaging/NVRTools/nuget/v3/index.json" -PublishLocation "https://navertica.pkgs.visualstudio.com/_packaging/NVRTools/nuget/v3/index.json"
    nuget sources add -Name NVRTools -Source 'https://navertica.pkgs.visualstudio.com/_packaging/NVRTools/nuget/v2' -Username 'xxx@navertica.com' -Password xxx
    publish-module -Path .\ -Repository NVRTools -NuGetApiKey VSTS -Credential $cred
}