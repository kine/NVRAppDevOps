function PublishNVRAppDevOpsModule
{
    UnRegister-PSRepository -Name "NVRTools"
    $cred = Get-Credential
    #6izkrrrwe74itisdxdvdkdvczl2ew5zkmq2dbj2jkr7nt3spaana
    Register-PSRepository -Name "NVRTools" -SourceLocation "https://navertica.pkgs.visualstudio.com/_packaging/NVRTools/nuget/v2" -PublishLocation "http://tfs:8080/tfs/Dynamics_NAV/_packaging/NVRTools/nuget/v2" -Credential $cred
    #Register-PSRepository -Name "NVRTools" -SourceLocation "https://navertica.pkgs.visualstudio.com/_packaging/NVRTools/nuget/v3/index.json" -PublishLocation "https://navertica.pkgs.visualstudio.com/_packaging/NVRTools/nuget/v3/index.json"
    #.\nuget.exe sources add -name NVRTools -source https://navertica.pkgs.visualstudio.com/_packaging/NVRTools/nuget/v2 -username ksacek -password  -storePasswordInClearText
    publish-module -Path .\ -Repository NVRTools -NuGetApiKey VSTS -Credential $cred
}