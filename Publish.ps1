function PublishNVRAppDevOpsModule
{
    UnRegister-PSRepository -Name "NVRTools"
    Register-PSRepository -Name "NVRTools" -SourceLocation "http://tfs:8080/tfs/Dynamics_NAV/_packaging/NVRTools/nuget/v2" -PublishLocation "http://tfs:8080/tfs/Dynamics_NAV/_packaging/NVRTools/nuget/v2"
    publish-module -Path .\ -Repository NVRTools -NuGetApiKey VSTS
}